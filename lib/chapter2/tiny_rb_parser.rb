# rbs_inline: enabled

require_relative "../parser/parser"

class TinyRbParser
  class Term; end

  class TrueTerm < Term; end

  class FalseTerm < Term; end

  class IfTerm < Term
    attr_accessor :cond, :thn, :els #: Term
    #: (cond: Term, thn: Term, els: Term) -> void
    def initialize(cond:, thn:, els:)
      @cond = cond
      @thn = thn
      @els = els
    end
  end

  class NumberTerm < Term
    attr_accessor :n #: Integer
    #: (n: Integer) -> void
    def initialize(n:)
      @n = n
    end
  end

  class AddTerm < Term
    attr_accessor :left, :right #: Term
    #: (left: Term, right: Term) -> void
    def initialize(left:, right:)
      @left = left
      @right = right
    end
  end

  #: (String) -> Term
  def self.parse(source)
    term(Parser.new(source).parse)
  rescue RuntimeError => e
    raise "#{e.message}; source => #{source}"
  end

  # type Term =
  #   | { tag: "true" }
  #   | { tag: "false" }
  #   | { tag: "if"; cond: Term; thn: Term; els: Term }
  #   | { tag: "number"; n: number }
  #   | { tag: "add"; left: Term; right: Term };
  #: (Hash[Symbol, untyped]) -> Term
  def self.term(node)
    case
    when node[:tag] == "true"
      TrueTerm.new
    when node[:tag] == "false"
      FalseTerm.new
    when node[:tag] == "if"
      IfTerm.new(cond: term(node[:cond]), thn: term(node[:thn]), els: term(node[:els]))
    when node[:tag] == "number"
      NumberTerm.new(n: node[:n])
    when node[:tag] == "add"
      AddTerm.new(left: term(node[:left]), right: term(node[:right]))
    else
      raise "Unknown node type; node => #{node}"
    end
  end
end
