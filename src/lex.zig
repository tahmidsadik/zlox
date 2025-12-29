const std = @import("std");
var gpa: std.mem.Allocator = undefined;

const buf: []u8 = undefined;
var writer = std.fs.File.stdout().writer(buf);

const TokenType = union(enum) {
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
    literal_string: []const u8,
    literal_number,

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

const LexError = error{ EOFReached, UnterminatedStringLiteral };

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

    fn safe_to_peek(self: *Lexer, from_idx: u32) bool {
        if (from_idx + 1 < self.src_len) {
            return true;
        }

        return false;
    }

    fn peek(self: *Lexer, from_idx: u32) !u8 {
        if (!self.safe_to_peek(from_idx)) {
            return LexError.EOFReached;
        }

        return self.src[from_idx + 1];
    }

    // moves the current_idx to the found_character idx if found
    // otherwise throws an error
    fn peek_until_match(self: *Lexer, to_match: u8) ![]const u8 {
        if (!self.safe_to_peek(self.current_idx)) {
            return LexError.UnterminatedStringLiteral;
        }

        const start_idx = self.current_idx;
        var cchar = try self.peek(start_idx);
        var end_idx = start_idx + 1;

        while (cchar != to_match) {
            // std.debug.print("cchar: {c}, to_match: {c}\n", .{ cchar, to_match });
            if (self.safe_to_peek(end_idx)) {
                cchar = try self.peek(end_idx);
                end_idx = end_idx + 1;
            } else {
                return LexError.UnterminatedStringLiteral;
            }
        }

        const string_val = self.src[start_idx + 1 .. end_idx];
        self.current_idx = end_idx;

        return string_val;
    }

    fn lex_string(self: *Lexer) !TokenType {
        const xx = try self.peek_until_match('"');
        return .{ .literal_string = xx };
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
        } else if (char == '"') {
            const response = self.lex_string();
            if (response) |tt| {
                return tt;
            } else |err| {
                switch (err) {
                    LexError.UnterminatedStringLiteral => {
                        const err_msg = "Unterminated String Literal Detected - couldn't find closing \" starting from idx {d}\n";
                        std.debug.print(err_msg, .{self.current_idx});
                    },
                    LexError.EOFReached => {
                        const err_msg = "Unexpectedly reached EOF\n";
                        std.debug.print(err_msg, .{});
                    },
                }
                return TokenType.none;
            }
        }

        return TokenType.none;
    }

    fn print_tokens(self: *const Lexer) void {
        for (self.parsed_tokens.items) |tok| {
            switch (tok) {
                .literal_string => |value| {
                    std.debug.print("String({s})\n", .{value});
                },
                TokenType.none => {},
                else => {
                    std.debug.print("Token = {s}\n", .{@tagName(tok)});
                },
            }
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
