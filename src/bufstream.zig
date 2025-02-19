const std = @import("std");

const dbg = @import("zut").dbg;
const Allocator = std.mem.Allocator;

pub const BufStream = struct {
    buf: []const u8,
    i: usize = 0,

    pub const Error = Allocator.Error || @typeInfo(@typeInfo(@TypeOf(dbg.rtAssert)).@"fn".return_type.?).error_union.error_set;
    pub const Reader = std.io.Reader(*BufStream, Error, BufStream.read);

    pub fn read(self: *BufStream, dest: []u8) Error!usize {
        try dbg.rtAssert(self.i + dest.len <= self.buf.len, error.Read);

        @memcpy(dest, self.buf[self.i .. self.i + dest.len]);
        self.i += dest.len;
        return dest.len;
    }

    pub fn fromFile(allocator: Allocator, path: []const u8) !BufStream {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        return BufStream{ .buf = try if (file.metadata()) |m|
            file.readToEndAllocOptions(allocator, m.size(), m.size(), 1, null)
        else |_|
            file.readToEndAlloc(allocator, 100e6) };
    }

    pub fn slice(self: BufStream, offset: usize, size: usize) !BufStream {
        try dbg.rtAssert(offset + size <= self.buf.len, error.Slice);

        return BufStream{ .buf = self.buf[offset .. offset + size] };
    }

    pub fn skip(self: *BufStream, bytes: usize) !void {
        const i = self.i + bytes;

        try dbg.rtAssert(i < self.buf.len, error.Skip);

        self.i = i;
    }

    pub fn readU8(self: *BufStream) !u8 {
        try dbg.rtAssert(self.i < self.buf.len, error.ReadU8);

        const ret = self.buf[self.i];
        self.i += 1;
        return ret;
    }

    pub fn readAs(self: *BufStream, comptime T: type) !T {
        const bytes = @sizeOf(T);
        const start = self.i;
        self.i += bytes;

        try dbg.rtAssert(self.i <= self.buf.len, error.ReadAs);

        return std.mem.readInt(T, self.buf[start .. start + bytes][0..bytes], .big);
    }

    pub fn readTo(self: *BufStream, out: []u8) !void {
        const bytes = out.len;
        const start = self.i;
        self.i += bytes;

        try dbg.rtAssert(self.i <= self.buf.len, error.ReadTo);

        @memcpy(out, self.buf[start .. start + bytes]);
    }

    pub fn readUntilDelimeter(self: *BufStream, dest: ?[]u8, delimeter: u8) usize {
        if (self.i >= self.buf.len) {
            return 0;
        }
        if (dest) |d| {
            var i: usize = 0;
            while (self.buf[self.i] != delimeter) {
                d[i] = self.buf[self.i];
                i += 1;
                self.i += 1;
            }

            return i;
        } else {
            var i: usize = self.i;
            var len: usize = 0;
            while (self.buf[i] != delimeter) {
                len += 1;
                i += 1;
            }

            return len;
        }
    }

    pub fn readToEnd(self: *BufStream, dest: ?[]u8) usize {
        const len = self.remainingBytes();
        if (dest) |d| {
            @memcpy(d, self.buf[self.i..]);
        }
        return len;
    }

    pub fn remainingBytes(self: BufStream) usize {
        return self.buf.len - self.i;
    }
};
