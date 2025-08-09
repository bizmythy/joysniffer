const std = @import("std");
const lib = @import("joysniffer_lib");
const c = @cImport({
    @cInclude("linux/joystick.h"); // <-- joydev, defines struct js_event
});

const fs = std.fs;

fn closeFiles(file_list: std.ArrayList(fs.File)) void {
    for (file_list.items) |file| {
        file.close();
    }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const device_dir = "/dev/input";

    // Open the current working directory as an iterable directory.
    var dir = try fs.openDirAbsolute(device_dir, fs.Dir.OpenOptions{ .iterate = true });
    defer dir.close();

    var js_file_list = std.ArrayList(fs.File).init(allocator);
    defer js_file_list.deinit();

    var iter = dir.iterateAssumeFirstIteration();
    while (try iter.next()) |entry| {
        if (std.mem.eql(u8, entry.name[0..2], "js")) {
            std.debug.print("Joy device found: {s}\n", .{entry.name});
            const path = try fs.path.join(allocator, &[2][]const u8{ device_dir, entry.name });
            const f = try fs.openFileAbsolute(path, .{ .mode = fs.File.OpenMode.read_only });
            try js_file_list.append(f);
        }
    }
    defer closeFiles(js_file_list);

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
