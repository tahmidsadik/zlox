const zlox = @import("zlox");

const lex = @import("lex.zig");

const std = @import("std");
const stdout_buf: []u8 = undefined;
var writer = std.fs.File.stdout().writer(stdout_buf);

var input_src: [1024]u8 = undefined;
const stdin = std.fs.File.stdin();
var reader = stdin.reader(&input_src);

pub fn prompt() !void {
    const promptMsg = "> ";
    try writer.interface.print("{s}", .{promptMsg});
}

pub fn read_input() ![]u8 {
    const src = try reader.interface.takeDelimiter('\n') orelse unreachable;
    return src;
}

pub fn greetUser() !void {
    const greetUserMsg = "Zlox Repl - Version 0.0.1\n";
    try writer.interface.print("{s}", .{greetUserMsg});
}

pub fn repl() !void {
    try greetUser();
    while (true) {
        try prompt();
        const src = try read_input();
        try writer.interface.print("Source = {s}\n", .{src});
        const ll = lex.Lexer{ .src = src };
        try ll.lex();
    }
}

pub fn main() !void {
    try repl();
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
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
