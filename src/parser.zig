const std = @import("std");
const lex = @import("lex.zig");

pub var gpa: std.mem.Allocator = undefined;

const Expression = struct { token: lex.TokenType };

const PrimaryExpression = union(enum) { LiteralString: []const u8, LiteralNumber: []const u8, true, false, nil, LeftParen, RightParen };

fn print_expresisons(exprs: std.ArrayList(PrimaryExpression)) void {
    std.debug.print("------------------- Printing expressions -------------------\n", .{});
    for (exprs.items) |expr| {
        switch (expr) {
            .LiteralString => |val| {
                std.debug.print("LiteralString({s})\n", .{val});
            },
            .LiteralNumber => |val| {
                std.debug.print("LiteralNumber({s})\n", .{val});
            },
            else => {
                std.debug.print("{s}\n", .{@tagName(expr)});
            },
        }
    }

    std.debug.print("------------------- Printing expressions -------------------\n", .{});
}

pub const Parser = struct {
    tokens: std.ArrayList(lex.TokenType),

    pub fn init(token_list: std.ArrayList(lex.TokenType)) Parser {
        return Parser{ .tokens = token_list };
    }

    // pub fn expression() Expression {
    //     return equality();
    // }

    // pub fn equality() {
    //
    // }

    pub fn unary(self: *Parser) Expression {
            

    }

    pub fn parse(self: *Parser) !void {
        var i: usize = 0;

        var expressions = try std.ArrayList(PrimaryExpression).initCapacity(gpa, 8);

        // expression     → equality ;
        // equality       → comparison ( ( "!=" | "==" ) comparison )* ;
        // comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
        // term           → factor ( ( "-" | "+" ) factor )* ;
        // factor         → unary ( ( "/" | "*" ) unary )* ;
        // unary          → ( "!" | "-" ) unary | primary ;
        // primary        → NUMBER | STRING | "true" | "false" | "nil" | "(" expression ")" ;”

        while (i < self.tokens.items.len) {
            const tok = self.tokens.items[i];
            var parsed_val: PrimaryExpression = undefined;

            switch (tok) {
                .true => {
                    parsed_val = PrimaryExpression.true;
                },
                .false => {
                    parsed_val = PrimaryExpression.false;
                },
                .nil => {
                    parsed_val = PrimaryExpression.nil;
                },
                .literal_string => |string_val| {
                    parsed_val = .{ .LiteralString = string_val };
                },
                .literal_number => |number_val| {
                    parsed_val = .{ .LiteralNumber = number_val };
                },
                else => {
                    parsed_val = .{ .LiteralString = "Undefined" };
                },
            }

            const err = try expressions.append(gpa, parsed_val);
            _ = err;

            i = i + 1;
        }

        print_expresisons(expressions);
    }
};

// expression     → equality ;
// equality       → comparison ( ( "!=" | "==" ) comparison )* ;
// comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
// term           → factor ( ( "-" | "+" ) factor )* ;
// factor         → unary ( ( "/" | "*" ) unary )* ;
// unary          → ( "!" | "-" ) unary | primary ;
// primary        → NUMBER | STRING | "true" | "false" | "nil" | "(" expression ")" ;”

// 3 + 7 - 2

// equality() => comparision() =>   term() =>    factor() => unary() => primary
//
//
// ExprLiteral(3) 
// Right = NumberLiteral(7)
// expr = Expr.Binary(NumberLiteral(3), Operator(Plus),  NumberLiteral(7))
//
// current = Minus
// operator = previous() = Minus
// Right = NumberLiteral(2)
//
//
// expr = Expr.Binary( Expr.Binary(NumberLiteral(3), Operator(Plus),  NumberLiteral(7)), Operator(Minus), NumberLiteral(2))



// expression => 
