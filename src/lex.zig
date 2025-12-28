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
    semicolon,
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
    none,

    pub fn fromString(char: []const u8) TokenType {
        // Keywords
        if (std.mem.eql(u8, char, "and")) {
            return TokenType.bool_and;
        } else if (std.mem.eql(u8, char, "or")) {
            return TokenType.bool_or;
        } else if (std.mem.eql(u8, char, "not")) {
            return TokenType.bool_not;
        } else if (std.mem.eql(u8, char, "if")) {
            return TokenType.bool_if;
        } else if (std.mem.eql(u8, char, "true")) {
            return TokenType.true;
        } else if (std.mem.eql(u8, char, "false")) {
            return TokenType.false;
        }

        // Braces and parens

        else if (std.mem.eql(u8, char, "{")) {
            return TokenType.left_brace;
        } else if (std.mem.eql(u8, char, "}")) {
            return TokenType.right_brace;
        } else if (std.mem.eql(u8, char, "(")) {
            return TokenType.left_paren;
        } else if (std.mem.eql(u8, char, ")")) {
            return TokenType.right_paren;
        }

        // Special characters
        else if (std.mem.eql(u8, char, ",")) {
            return TokenType.comma;
        } else if (std.mem.eql(u8, char, ".")) {
            return TokenType.dot;
        } else if (std.mem.eql(u8, char, "-")) {
            return TokenType.minus;
        } else if (std.mem.eql(u8, char, "+")) {
            return TokenType.plus;
        } else if (std.mem.eql(u8, char, ";")) {
            return TokenType.semicolon;
        } else if (std.mem.eql(u8, char, "/")) {
            return TokenType.slash;
        } else if (std.mem.eql(u8, char, "*")) {
            return TokenType.star;
        } else if (std.mem.eql(u8, char, ".")) {
            return TokenType.dot;
        } else if (std.mem.eql(u8, char, "EOF")) {
            return TokenType.EOF;
        } else if (std.mem.eql(u8, char, "!")) {
            return TokenType.bang;
        } else if (std.mem.eql(u8, char, "!=")) {
            return TokenType.bang_equal;
        } else if (std.mem.eql(u8, char, "=")) {
            return TokenType.equal;
        } else if (std.mem.eql(u8, char, "==")) {
            return TokenType.equal_equal;
        } else if (std.mem.eql(u8, char, ">")) {
            return TokenType.greater;
        } else if (std.mem.eql(u8, char, ">=")) {
            return TokenType.greater_equal;
        } else if (std.mem.eql(u8, char, "<")) {
            return TokenType.less;
        } else if (std.mem.eql(u8, char, "<=")) {
            return TokenType.less_equal;
        } else {
            return TokenType.none;
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
            // try writer.interface.print("char = {c}\n", .{c});
            const tt = TokenType.fromString(&[_]u8{c});
            std.debug.print("{s}\n", .{@tagName(tt)});
        }
    }
};
