const std = @import("std");
const lex = @import("lex.zig");

const TokenType = lex.TokenType;

const Expression = struct {};
pub const Parser = struct {
    toknes: std.ArrayList(TokenType),

    pub fn init(token_list: std.ArrayList(TokenType)) Parser {
        return Parser{ .tokens = token_list };
    }
};
