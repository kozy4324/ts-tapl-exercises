# --- Step 1: Tokenizer ---
class Tokenizer
  KEYWORDS = %w[true false]
  SYMBOLS = %w[+ ? : ( )]

  def initialize(input)
    @input = input
    @pos = 0
  end

  def next_token
    skip_whitespace
    return nil if eof?
    c = peek
    if c =~ /[0-9]/
      read_number
    elsif letter = read_keyword
      letter
    elsif SYMBOLS.include?(c)
      @pos += 1
      c
    else
      raise "Unexpected character: #{c}"
    end
  end

  def tokenize
    tokens = []
    while (tok = next_token)
      tokens << tok
    end
    tokens
  end

  private
  def skip_whitespace
    @pos += 1 while !eof? && @input[@pos] =~ /\s/
  end

  def eof?
    @pos >= @input.size
  end

  def peek
    @input[@pos]
  end

  def read_number
    start = @pos
    @pos += 1 while !eof? && @input[@pos] =~ /[0-9]/
    { type: :number, value: @input[start...@pos].to_i }
  end

  def read_keyword
    KEYWORDS.each do |kw|
      if @input[@pos, kw.size] == kw
        @pos += kw.size
        return { type: :keyword, value: kw }
      end
    end
    nil
  end
end

# --- Step 2: AST Node (Ruby hash) ---
# Rubyではハッシュで表現。
# type Term =
#   | { tag: "true" }
#   | { tag: "false" }
#   | { tag: "if"; cond: Term; thn: Term; els: Term }
#   | { tag: "number"; n: number }
#   | { tag: "add"; left: Term; right: Term };

# --- Step 3: Literal Parser ---
class Parser
  def initialize(input)
    @tokens = Tokenizer.new(input).tokenize
    @pos = 0
  end

  def parse
    parse_if
  end

  private
  # if式: cond ? thn : els
  def parse_if
    cond = parse_term
    if peek_token == "?"
      next_token # consume ?
      thn = parse_term
      expect_token(":")
      els = parse_term
      { tag: "if", cond: cond, thn: thn, els: els }
    else
      cond
    end
  end

  # 加算式: term = factor ("+" factor)*
  def parse_term
    node = parse_factor
    while peek_token == "+"
      next_token # consume "+"
      right = parse_factor
      node = { tag: "add", left: node, right: right }
    end
    node
  end

  # factor: 数値・true/false・括弧
  def parse_factor
    tok = next_token
    case tok
    when Hash
      if tok[:type] == :number
        { tag: "number", n: tok[:value] }
      elsif tok[:type] == :keyword
        case tok[:value]
        when "true"
          { tag: "true" }
        when "false"
          { tag: "false" }
        else
          raise "Unknown keyword: #{tok[:value]}"
        end
      else
        raise "Unknown token: #{tok}"
      end
    when "("
      node = parse_if
      expect_token(")")
      node
    else
      raise "Unexpected token: #{tok.inspect}"
    end
  end

  def next_token
    return nil if @pos >= @tokens.size
    tok = @tokens[@pos]
    @pos += 1
    tok
  end

  def peek_token
    return nil if @pos >= @tokens.size
    @tokens[@pos]
  end

  def expect_token(val)
    tok = next_token
    raise "Expected '#{val}', got '#{tok}'" unless tok == val
  end
end

# --- テスト例 ---
if __FILE__ == $0
  p Parser.new("true").parse #=> { tag: "true" }
  p Parser.new("false").parse #=> { tag: "false" }
  p Parser.new("42").parse #=> { tag: "number", n: 42 }
  p Parser.new("1 + 2").parse #=> { tag: "add", left: {tag: "number", n: 1}, right: {tag: "number", n: 2} }
  p Parser.new("1 + 2 + 3").parse #=> { tag: "add", left: {tag: "add", left: {tag: "number", n: 1}, right: {tag: "number", n: 2}}, right: {tag: "number", n: 3} }
  p Parser.new("1 + (2 + 3)").parse #=> { tag: "add", left: {tag: "number", n: 1}, right: {tag: "add", left: {tag: "number", n: 2}, right: {tag: "number", n: 3}} }
  p Parser.new("1 ? 1 : 2").parse #=> {tag: "if", cond: {tag: "number", n: 1}, thn: {tag: "number", n: 1}, els: {tag: "number", n: 2}}
  p Parser.new("true ? 1 : 2").parse #=> { tag: "if", cond: {tag: "true"}, thn: {tag: "number", n: 1}, els: {tag: "number", n: 2} }
  p Parser.new("true ? false : true").parse #=> { tag: "if", cond: {tag: "true"}, thn: {tag: "false"}, els: {tag: "true"} }
  p Parser.new("true ? 1 : true").parse #=> { tag: "if", cond: {tag: "true"}, thn: {tag: "number", n: 1}, els: {tag: "true"} }
  p Parser.new("true ? (1 + 2) : (3 + (false ? 4 : 5))").parse #=> { tag: "if", cond: {tag: "true"}, thn: {tag: "add", left: {tag: "number", n: 1}, right: {tag: "number", n: 2}}, els: {tag: "add", left: {tag: "number", n: 3}, right: {tag: "if", cond: {tag: "false"}, thn: {tag: "number", n: 4}, els: {tag: "number", n: 5}}} }
end
