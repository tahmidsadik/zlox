const std = @import("std");

pub var gpa: std.mem.Allocator = undefined;

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

    fun,
    class,
    super,
    this,

    loop_while,
    loop_for,

    nil,
    print_stmt,
    return_stmt,
    var_stmt,

    EOF,
    // identifiers
    identifier: []const u8,
    literal_string: []const u8,
    literal_number: []const u8,

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

var map_kw: std.StringHashMap(TokenType) = undefined;

pub fn init_kw() void {
    map_kw = std.StringHashMap(TokenType).init(gpa);
    try map_kw.put("and", .{.bool_and});
    try map_kw.put("or", .{.bool_or});
    try map_kw.put("not", .{.bool_not});

    try map_kw.put("if", .{.bool_if});
    try map_kw.put("else", .{.bool_else});

    try map_kw.put("true", .{.bool_if});
    try map_kw.put("false", .{.bool_else});

    try map_kw.put("class", .{.class});
    try map_kw.put("for", .{.loop_for});
    try map_kw.put("fun", .{.fun});

    try map_kw.put("nil", .{.nil});

    try map_kw.put("print", .{.print});
    try map_kw.put("return", .{.return_stmt});
    try map_kw.put("super", .{.super});

    try map_kw.put("this", .{.this});
    try map_kw.put("var", .{.var_stmt});
    try map_kw.put("while", .{.loop_while});
}

// checks whether the given string is a keyword
pub fn is_keyword(key: []const u8) bool {
    return map_kw.contains(key);
}

pub fn try_parse_into_keyword(key: []const u8) ?TokenType {
    if (is_keyword(key)) {
        return map_kw.get(key).?;
    }

    return null;
}

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

    pub fn pgint_state(self: *const Lexer) void {
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

    // takes a function and keeps taking chracters as long as the function returns true
    fn peek_while(self: *Lexer, predicate_fn: fn (u8) bool) ![]const u8 {
        if (!self.safe_to_peek(self.current_idx)) {
            return self.src[self.current_idx..];
        }

        const start_idx = self.current_idx;
        var idx = start_idx;
        var c = try self.peek(self.current_idx);

        while (predicate_fn(c)) {
            idx = idx + 1;
            c = try self.peek(idx);
        }

        self.current_idx = idx;
        return self.src[start_idx .. idx + 1];
    }

    fn lex_string(self: *Lexer) !TokenType {
        const xx = try self.peek_until_match('"');
        return .{ .literal_string = xx };
    }

    fn is_number(c: u8) bool {
        return (c >= '0') and (c <= '9');
    }

    fn is_dot(c: u8) bool {
        return c == '.';
    }

    fn is_number_or_dot(c: u8) bool {
        return (is_number(c)) or (is_dot(c));
    }

    fn is_alpha(c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
    }

    // scan literal numbers
    // Numbers can be like
    // 11, 11.232 0.51
    // The rules is is number || is dot and then is number only
    fn lex_number(self: *Lexer) TokenType {
        if (!self.safe_to_peek(self.current_idx)) {
            return .{ .literal_number = self.src[self.current_idx..] };
        }

        const start = self.current_idx;
        var i = start;
        var allow_dot = true;
        var cchar = self.peek(i) catch unreachable;

        while (true) {
            if (is_dot(cchar)) {
                if (allow_dot == true) {
                    allow_dot = false;
                } else {
                    break;
                }
            } else if (!is_number(cchar)) {
                break;
            }

            i = i + 1;

            if (!self.safe_to_peek(i)) {
                break;
            }

            cchar = self.peek(i) catch unreachable;
        }

        self.current_idx = i;
        return .{ .literal_number = self.src[start .. i + 1] };
    }

    fn try_parse_one_or_two_char(self: *Lexer, char: u8) TokenType {
        if (char == '!') {
            if (self.advance_if_matched('=')) {
                return TokenType.bang_equal;
            }
            return TokenType.bang;
        } else if (char == '=') {
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
            switch (tok) {
                .literal_string => |value| {
                    std.debug.print("String({s})\n", .{value});
                },
                .literal_number => |value| {
                    std.debug.print("Number({s})\n", .{value});
                },
                .identifier => |value| {
                    std.debug.print("Identifier({s})\n", .{value});
                },
                TokenType.none => {},
                else => {
                    std.debug.print("Token({s})\n", .{@tagName(tok)});
                },
            }
        }
    }

    fn add_token(self: *Lexer, token: TokenType) !void {
        const err = try self.parsed_tokens.append(gpa, token);
        _ = err;
    }

    fn lex_single_token(self: *Lexer) TokenType {
        if (self.current_char == ' ') {
            return TokenType.none;
        }

        var token = TokenType.try_parse_with_single_char(self.current_char);

        if (token == TokenType.none) {
            token = self.try_parse_one_or_two_char(self.current_char);
        }

        if (token == TokenType.none) {
            if (is_number(self.current_char)) {
                token = self.lex_number();
            } else if (self.current_char == '"') {
                const response = self.lex_string();
                if (response) |tt| {
                    token = tt;
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
            } else if (is_alpha(self.current_char)) {
                const response = self.peek_while(is_alpha);
                if (response) |val| {
                    const kw = try_parse_into_keyword(val);

                    if (kw) |keyword| {
                        return keyword;
                    }

                    return .{ .identifier = val };
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
        }

        return token;
    }

    pub fn lex(self: *Lexer) !void {
        while (!self.eof_reached) {
            const token = self.lex_single_token();
            if (token != TokenType.none) {
                try self.add_token(token);
            }

            self.advance();
        }

        self.print_tokens();
    }
};
