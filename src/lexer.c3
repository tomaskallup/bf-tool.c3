module c3_bftool::lexer;

import std::io;
import std::collections::list;

struct Lexer {
  char[] data;
  usz pos;
}

enum TokenType: char (char token) {
  ERROR = 0,
  EOF = 0,

  PRINT = '.',
  READ = ',',

  INCP = '>',
  DECP = '<',

  INC = '+',
  DEC = '-',

  LOOPS = '[',
  LOOPE = ']',
}

struct Token (Printable) {
  TokenType type;
  usz pos;
}

fn String Token.to_string(&self, Allocator allocator) @dynamic
{
	return {self.type.token};
}

fn String Token[].to_string(&self, Allocator allocator) @dynamic
{
  char[] result = allocator::new_array(allocator, char, self.len);
  foreach (index, token: self) {
    result[index] = token.type.token;
  }

	return (String)result;
}

fn bool char[].contains(self, char needle) {
  foreach (char item: self) {
    if (item == needle) return true;
  }

  return false;
}

macro populate_token_table() {
  TokenType[256] $tmp = {};

  $foreach ($tokenType: TokenType.values)
    $tmp[$tokenType.token] = $tokenType;
  $endforeach

  return $tmp;
}

const TokenType[256] TOKEN_TABLE = populate_token_table();

fn bool is_valid_token(char needle) => TOKEN_TABLE[needle] != EOF && TOKEN_TABLE[needle] != ERROR;

fn Token Lexer.next(&self) {
  if (self.pos >= self.data.len) return { .type = EOF, .pos = self.pos };

  char c;

  while (!is_valid_token(c) && self.pos < self.data.len) c = self.data[self.pos++];

  return {
    .type = TOKEN_TABLE[c],
    .pos = self.pos - 1,
  };
}

fn Token[] Lexer.lex(&self) {
  List(<Token>) tokens;
  tokens.new_init();
  // defer tokens.free();

  Token c = self.next();
  while (c.type != EOF) {
    tokens.push(c);
    c = self.next();
  }

  return tokens.array_view();
}
