const std = @import("std");
const lib = @import("joysniffer_lib");
const c = @cImport({
    @cInclude("linux/joystick.h"); // <-- joydev, defines struct js_event
});

const fs = std.fs;

const Joysticks = struct {
    const Joystick = struct {
        file: fs.File,
        name: []const u8,
    };

    files: std.ArrayList(Joystick),

    pub fn init(allocator: std.mem.Allocator) !Joysticks {
        var dir = try fs.openDirAbsolute("/dev/input", fs.Dir.OpenOptions{ .iterate = true });
        defer dir.close();

        var joysticks = std.ArrayList(Joystick).init(allocator);

        var iter = dir.iterateAssumeFirstIteration();
        while (try iter.next()) |entry| {
            if (std.mem.eql(u8, entry.name[0..2], "js")) {
                const file = try dir.openFile(entry.name, .{ .mode = fs.File.OpenMode.read_only });
                try joysticks.append(Joystick{
                    .file = file,
                    .name = entry.name,
                });
            }
        }

        return Joysticks{
            .files = joysticks,
        };
    }

    pub fn deinit(self: *Joysticks) void {
        // close all files
        for (self.files.items) |joystick| {
            joystick.file.close();
        }
        // free list
        self.files.deinit();
    }

    pub fn print(self: *Joysticks) void {
        for (self.files.items) |file| {
            std.debug.print("Joy device found: {s}\n", .{file});
        }
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var joysticks = try Joysticks.init(allocator);
    defer joysticks.deinit();
    // var f = try fs.openFileAbsolute(device_dir, .{ .mode = fs.File.OpenMode.read_only });
    // defer f.close();

    // var ev: c.struct_js_event = undefined;

    // while (true) {
    //     const n = try f.read(std.mem.asBytes(&ev));
    //     if (n != @sizeOf(c.struct_js_event)) break;

    //     // js_event layout: time(ms), value(i16), type(u8), number(u8)
    //     std.debug.print("t={}ms type={d} num={d} val={d}\n", .{ ev.time, ev.type, ev.number, ev.value });
    // }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "use other module" {
    try std.testing.expectEqual(@as(i32, 150), lib.add(100, 50));
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
