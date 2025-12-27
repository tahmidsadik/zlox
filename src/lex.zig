const std = @import("std");

const buf: []u8 = undefined;
var writer = std.fs.File.stdout().writer(buf);

const oneOrTwoCharacter = enum {};

pub const MyType = enum { Okay, NotOkay };

const TokenType = enum(u8) {
    // keywords
    bool_and,
    bool_or,
    bool_not,
    bool_if,
    bool_else,
    true,
    false,

    EOF,
    // identifiers
    identifier,
    string,
    number,

    // Braces and parens
    left_brace,
    right_brace,
    left_paren,
    right_paren,

    // special symbols
    comma,
    dot,
    minus,
    plus,
    semiColon,
    slash,
    star,
    // one or multi characters
    bang,
    bang_equal,
    equal,
    equal_equal,
    greater,
    greater_equal,
    less,
    less_equal,
    none = 100000,

    pub fn fromString(char: []u8) TokenType {
        // Keywords
        if (std.mem.eql(u8, char, "and")) {
            TokenType.And;
        } else if (std.mem.eql(u8, char, "or")) {
            TokenType.Or;
        } else if (std.mem.eql(u8, char, "not")) {
            TokenType.Not;
        } else if (std.mem.eql(u8, char, "if")) {
            TokenType.If;
        } else if (std.mem.eql(u8, char, "true")) {
            TokenType.True;
        } else if (std.mem.eql(u8, char, "false")) {
            TokenType.False;
        }

        // Braces and parens

        else if (std.mem.eql(u8, char, "{")) {
            TokenType.LeftBrace;
        } else if (std.mem.eql(u8, char, "}")) {
            TokenType.RightBrace;
        } else if (std.mem.eql(u8, char, "(")) {
            TokenType.LeftParen;
        } else if (std.mem.eql(u8, char, ")")) {
            TokenType.RightParen;
        }

        // Special characters
        else if (std.mem.eql(u8, char, ",")) {
            TokenType.Comma;
        } else if (std.mem.eql(u8, char, ".")) {
            TokenType.Dot;
        } else if (std.mem.eql(u8, char, "-")) {
            TokenType.Minus;
        } else if (std.mem.eql(u8, char, "+")) {
            TokenType.Plus;
        } else if (std.mem.eql(u8, char, ";")) {
            TokenType.SemiColon;
        } else if (std.mem.eql(u8, char, "/")) {
            TokenType.Slash;
        } else if (std.mem.eql(u8, char, "*")) {
            TokenType.Star;
        } else if (std.mem.eql(u8, char, ".")) {
            TokenType.Dot;
        } else if (std.mem.eql(u8, char, "EOF")) {
            TokenType.EOF;
        } else {
            TokenType.None;
        }
    }
};

const Token = struct { line: u32, lexeme: []const u8, tokenType: TokenType };

pub fn getToken() Token {
    const ttype = TokenType.LeftBrace;
    const tok = Token{ .line = 1, .lexeme = "{", .tokenType = ttype };

    return tok;
}

// write a function that takes a string and process characters one by one
pub const Lexer = struct {
    src: []const u8,

    pub fn lex(self: *const Lexer) !void {
        for (self.src) |c| {
            try writer.interface.print("char = {c}\n", .{c});
        }
    }
};
