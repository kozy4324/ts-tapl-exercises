# rbs_inline: enabled

# @rbs!
#   type term = { tag: "true" }
#             | { tag: "false" }
#             | { tag: "if", cond: term, thn: term, els: term }
#             | { tag: "number", n: Integer }
#             | { tag: "add", left: term, right: term }
#             | { tag: "var", name: string }
#             | { tag: "func", params: Array[param], body: term }
#             | { tag: "call", func: term, args: Array[term] }

# @rbs!
#   type typ = { tag: "Boolean" }
#            | { tag: "Number" }
#            | { tag: "Func", params: Array[param], retType: typ }

# @rbs!
#   type param = { name: string, type: typ }

# @rbs!
#   type typeEnv = Hash[string, typ]

# --- Step 1: Tokenizer ---
class Tokenizer
  KEYWORDS = %w[true false]
  SYMBOLS = %w[+ ? : ( ) => ,]

  def initialize(input)
    @input = input
    @pos = 0
  end

  def next_token
    skip_whitespace
    return nil if eof?
    # 複合記号 =>
    if @input[@pos, 2] == "=>"
      @pos += 2
      return "=>"
    end
    c = peek
    if c =~ /[0-9]/
      read_number
    elsif c =~ /[a-zA-Z_]/
      read_ident
    elsif letter = read_keyword
      letter
    elsif SYMBOLS.include?(c)
      @pos += 1
      c
    else
      raise "Unexpected character: #{c}"
    end
  end

  def read_ident
    start = @pos
    @pos += 1 while !eof? && @input[@pos] =~ /[a-zA-Z0-9_]/
    { type: :ident, value: @input[start...@pos] }
  end

  def tokenize
    tokens = [] #: Array[untyped]
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

  # 加算式: term = call ("+" call)*
  def parse_term
    node = parse_call
    while peek_token == "+"
      next_token # consume "+"
      right = parse_call
      node = { tag: "add", left: node, right: right }
    end
    node
  end

  # 関数呼び出し: call = factor ("(" args ")")*
  def parse_call
    node = parse_factor
    while peek_token == "("
      next_token # consume '('
      args = [] #: Array[untyped]
      unless peek_token == ")"
        loop do
          args << parse_if
          break unless peek_token == ","
          next_token
        end
      end
      expect_token(")")
      node = { tag: "call", func: node, args: args }
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
      elsif tok[:type] == :ident
        # キーワードと一致する場合はキーワードとして扱う
        if tok[:value] == "true"
          { tag: "true" }
        elsif tok[:value] == "false"
          { tag: "false" }
        else
          { tag: "var", name: tok[:value] }
        end
      else
        raise "Unknown token: #{tok}"
      end
    when "("
      # 関数 or 括弧式
      if func_param_list?
        parse_func
      else
        node = parse_if
        expect_token(")")
        node
      end
    else
      raise "Unexpected token: #{tok.inspect}"
    end
  end

  # (x: number, y: boolean) => body
  def parse_func
    params = [] #: Array[untyped]
    # パラメータリスト
    loop do
      name_tok = next_token
      raise "Expected param name" unless name_tok.is_a?(Hash) && name_tok[:type] == :ident
      expect_token(":")
      type_tok = parse_type
      params << { name: name_tok[:value], type: type_tok }
      if peek_token == ","
        next_token
      else
        break
      end
    end
    expect_token(")")
    expect_token("=>")
    body = parse_if
    { tag: "func", params: params, body: body }
  end

  # Type型のパース
  def parse_type
    tok = next_token
    if tok.is_a?(Hash) && tok[:type] == :ident
      case tok[:value]
      when "number"
        { tag: "Number" }
      when "boolean"
        { tag: "Boolean" }
      else
        raise "Unknown type: #{tok[:value]}"
      end
    elsif tok == "("
      # 関数型 (x: number) => number
      param_types = [] #: Array[untyped]
      loop do
        name_tok = next_token
        raise "Expected param name in type" unless name_tok.is_a?(Hash) && name_tok[:type] == :ident
        expect_token(":")
        type_tok = parse_type
        param_types << { name: name_tok[:value], type: type_tok }
        if peek_token == ","
          next_token
        else
          break
        end
      end
      expect_token(")")
      expect_token("=>")
      ret_type = parse_type
      # コメントの期待値に合わせてキーは retType とする
      { tag: "Func", params: param_types, retType: ret_type }
    else
      raise "Unknown type syntax: #{tok.inspect}"
    end
  end

  def func_param_list?
    # 現在のトークン位置がパラメータリストの開始か判定
    # より柔軟にするため、単純なパターンマッチング
    save_pos = @pos
    begin
      # パラメータ名はident
      return false unless @pos < @tokens.size && @tokens[@pos].is_a?(Hash) && @tokens[@pos][:type] == :ident
      
      # ：が続く
      return false unless @pos + 1 < @tokens.size && @tokens[@pos + 1] == ":"
      
      # タイプの後には, か ) が続く必要がある
      # タイプ自体は複雑な可能性があるので細かくチェックしない
      i = @pos + 2
      # タイプをスキップ（括弧のネストも考慮）
      paren_count = 0
      while i < @tokens.size
        tok = @tokens[i]
        if tok == "("
          paren_count += 1
        elsif tok == ")"
          if paren_count == 0
            # パラメータリスト終了
            break
          end
          paren_count -= 1
        elsif tok == "," && paren_count == 0
          # 次のパラメータ
          break
        end
        i += 1
      end
      
      return false if i >= @tokens.size
      
      # ")" の後に "=>" があるか
      if @tokens[i] == ")"
        return false unless i + 1 < @tokens.size && @tokens[i + 1] == "=>"
      end
      
      true
    ensure
      @pos = save_pos
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
# コメントの通りに出力されることをRubyプログラムを実行して確認してください
# もしコメントの期待値と異なる出力となっている場合はコメントを正としてプログラムを続けて修正してください
# なお新たに追加したテスト例とコメントについてはその限りではありません。こちらから指示を行います。
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
  p Parser.new("(x: number) => 42").parse #=> { tag: "func", params: [{name: "x", type: {tag: "Number"}}], body: {tag: "number", n: 42} }
  p Parser.new("(x: boolean, y: number) => x + y").parse #=> { tag: "func", params: [{name: "x", type: {tag: "Boolean"}}, {name: "y", type: {tag: "Number"}}], body: {tag: "add", left: {tag: "var", name: "x"}, right: {tag: "var", name: "y"}} }
  p Parser.new("(x: number) => x").parse #=> { tag: "func", params: [{name: "x", type: {tag: "Number"}}], body: {tag: "var", name: "x"} }
  p Parser.new("(x: number, y: number) => x + y").parse #=> { tag: "func", params: [{name: "x", type: {tag: "Number"}}, {name: "y", type: {tag: "Number"}}], body: {tag: "add", left: {tag: "var", name: "x"}, right: {tag: "var", name: "y"}} }
  p Parser.new("(x: number, y: number) => x + z").parse #=> { tag: "func", params: [{name: "x", type: {tag: "Number"}}, {name: "y", type: {tag: "Number"}}], body: {tag: "add", left: {tag: "var", name: "x"}, right: {tag: "var", name: "z"}} }
  p Parser.new("1 + true").parse #=> {tag: "add", left: {tag: "number", n: 1}, right: {tag: "true"}}
  p Parser.new("((x: number) => x)(42)").parse #=> { tag: "call", func: { tag: "func", params: [{name: "x", type: {tag: "Number"}}], body: {tag: "var", name: "x"} }, args: [{tag: "number", n: 42}] }
  p Parser.new("((x: number) => x)(true)").parse #=> { tag: "call", func: { tag: "func", params: [{name: "x", type: {tag: "Number"}}], body: {tag: "var", name: "x"} }, args: [{tag: "true"}] }
  p Parser.new("((x: number) => 42)(1, 2, 3)").parse #=> { tag: "call", func: { tag: "func", params: [{name: "x", type: {tag: "Number"}}], body: {tag: "number", n: 42} }, args: [{tag: "number", n: 1}, {tag: "number", n: 2}, {tag: "number", n: 3}] }
  p Parser.new("(f: (x: number) => number) => 1").parse #=> { tag: "func", params: [{name: "f", type: { tag: "Func", params: [{name: "x", type: {tag: "Number"}}], retType: {tag: "Number"} }}], body: {tag: "number", n: 1} }
end
