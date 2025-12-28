const std = @import("std");
var gpa: std.mem.Allocator = undefined;

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

    fn try_parse_with_single_char(char: u8) TokenType {
        if (char == '{') {
            return TokenType.left_brace;
        } else if (char == '}') {
            return TokenType.right_brace;
        } else if (char == '(') {
            return TokenType.left_paren;
        } else if (char == ')') {
            return TokenType.right_paren;
        }

        // Special characters
        else if (char == ',') {
            return TokenType.comma;
        } else if (char == '.') {
            return TokenType.dot;
        } else if (char == '-') {
            return TokenType.minus;
        } else if (char == '+') {
            return TokenType.plus;
        } else if (char == ';') {
            return TokenType.semicolon;
        } else if (char == '/') {
            return TokenType.slash;
        } else if (char == '*') {
            return TokenType.star;
        }

        return TokenType.none;
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
    // allocator: std.mem.
    src: []const u8,
    current_char: u8,
    current_idx: u32 = 0,
    parsed_tokens: std.ArrayList(TokenType),
    src_len: usize,
    eof_reached: bool = false,

    pub fn init(alloc: std.mem.Allocator, src: []const u8) !Lexer {
        // initialize global allocator

        gpa = alloc;

        const tokens = try std.ArrayList(TokenType).initCapacity(alloc, 16);
        const new_lexer = Lexer{ .src = src, .parsed_tokens = tokens, .current_char = src[0], .current_idx = 0, .src_len = src.len };

        return new_lexer;
    }

    pub fn print_state(self: *const Lexer) void {
        std.debug.print("current_char = {c}, current_idx = {d} \n", .{ self.current_char, self.current_idx });
    }

    pub fn advance(self: *Lexer) void {
        if (self.current_idx + 1 >= self.src_len) {
            self.eof_reached = true;
            return;
        }

        self.current_idx = self.current_idx + 1;
        self.current_char = self.src[self.current_idx];
    }

    fn advance_if_matched(self: *Lexer, char_to_match: u8) bool {
        if (self.current_idx + 1 >= self.src_len) {
            return false;
        }

        // std.debug.print("(idx+1): {c}, char_to_match: {c}\n", .{ self.src[self.current_idx + 1], char_to_match });

        if (self.current_idx + 1 < self.src_len and self.src[self.current_idx + 1] == char_to_match) {
            self.current_idx = self.current_idx + 1;
            return true;
        }

        return false;
    }

    fn try_parse_one_or_two_char(self: *Lexer, char: u8) TokenType {
        if (char == '!') {
            if (self.advance_if_matched('=')) {
                return TokenType.bang_equal;
            }
            return TokenType.bang;
        } else if (char == '=') {
            std.debug.print("current_char: {c}, current_idx: {d}\n", .{ self.current_char, self.current_idx });

            if (self.advance_if_matched('=')) {
                return TokenType.equal_equal;
            }
            return TokenType.equal;
        } else if (char == '<') {
            if (self.advance_if_matched('=')) {
                return TokenType.less_equal;
            }
            return TokenType.less;
        } else if (char == '>') {
            if (self.advance_if_matched('=')) {
                return TokenType.greater_equal;
            }
            return TokenType.greater;
        }

        return TokenType.none;
    }

    fn print_tokens(self: *const Lexer) void {
        for (self.parsed_tokens.items) |tok| {
            std.debug.print("Token = {s}\n", .{@tagName(tok)});
        }
    }

    fn add_token(self: *Lexer, token: TokenType) !void {
        const err = try self.parsed_tokens.append(gpa, token);
        _ = err;
    }

    fn lex_single_token(self: *Lexer) TokenType {
        var token = TokenType.try_parse_with_single_char(self.current_char);

        if (token == TokenType.none) {
            token = self.try_parse_one_or_two_char(self.current_char);
        }

        return token;
    }

    pub fn lex(self: *Lexer) !void {
        while (!self.eof_reached) {
            const token = self.lex_single_token();
            try self.add_token(token);

            self.advance();
        }

        std.debug.print("EOF Reached\n", .{});
        self.print_tokens();
    }
};
