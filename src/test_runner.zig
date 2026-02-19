const std = @import("std");
const builtin = @import("builtin");
const Clock = std.Io.Clock;


pub fn main(init: std.process.Init) !void {
    const test_count = builtin.test_functions.len;
    if(test_count <= 0)
        return;

    var error_count: u24 = 0;
    std.debug.print("\nRunning {} tests...\n------------------------------------------------------------------------------------\n", .{test_count});
    
    for(builtin.test_functions) |test_func| {        
        const name = extractName(test_func);
        std.debug.print("\x1b[2m[{s}]\x1b[0m\n", .{ name });

        std.testing.allocator_instance = .{};
        const now = Clock.awake.now(init.io);

        test_func.func() catch |err| {
            error_count += 1;
            std.debug.print("\x1b[31mFailed because {}\x1b[0m\n", .{ err });
            std.debug.print("------------------------------------------------------------------------------------\n", .{});
            continue;
        };

        if(std.testing.allocator_instance.deinit() == std.heap.Check.leak) {
            std.debug.print("\x1b[31mFailed because memory is leaking\x1b[0m\n", .{});
            std.debug.print("------------------------------------------------------------------------------------\n", .{});
            continue;
        }
        const delay = Clock.awake.now(init.io).toNanoseconds() - now.toNanoseconds();
        std.debug.print("\x1b[32mPassed after {}mcs\x1b[0m\n", .{  @as(f32, @floatFromInt(delay)) / 1000 });
        std.debug.print("------------------------------------------------------------------------------------\n", .{});
    }
    std.debug.print("{}/{} tests passed\n\n", .{ test_count - error_count, test_count });
}



pub fn extractName(test_func: std.builtin.TestFn) []const u8 {
    const marker = std.mem.lastIndexOf(u8, test_func.name, ".test.") orelse return test_func.name;
    return test_func.name[marker+6..];
}
