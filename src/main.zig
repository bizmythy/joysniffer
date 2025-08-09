const std = @import("std");
const lib = @import("joysniffer_lib");
const c = @cImport({
    @cInclude("linux/joystick.h"); // <-- joydev, defines struct js_event
});

pub fn main() !void {
    // var gpa = std.heap.page_allocator;
    const device_path = "/dev/input/js0";

    var f = try std.fs.openFileAbsolute(device_path, .{ .mode = std.fs.File.OpenMode.read_only });
    defer f.close();

    var ev: c.struct_js_event = undefined;

    while (true) {
        const n = try f.read(std.mem.asBytes(&ev));
        if (n != @sizeOf(c.struct_js_event)) break;

        // js_event layout: time(ms), value(i16), type(u8), number(u8)
        std.debug.print("t={}ms type={d} num={d} val={d}\n", .{ ev.time, ev.type, ev.number, ev.value });
    }
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
