# rbs_inline: enabled

require "prism"

module Chapter3
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
      result = Prism.parse(source) # Prism::ParseResult
      statements = result.value.statements # Prism::StatementsNode
      nodes = statements.body # Array[Prism::node]
      node = nodes.first # Prism::node

      term(node)
    rescue RuntimeError => e
      raise "#{e.message}; source => #{source}"
    end

    #: (Prism::node) -> Term
    def self.term(node)
      case
      when node.is_a?(Prism::TrueNode)
        TrueTerm.new
      when node.is_a?(Prism::FalseNode)
        FalseTerm.new
      when node.is_a?(Prism::IfNode)
        statements = node.statements or raise "Unknown node type"
        subsequent = node.subsequent or raise "Unknown node type"
        raise "Unknown node type" unless subsequent.is_a?(Prism::ElseNode)
        elsNode = subsequent.statements&.body&.first or raise "Unknown node type"
        IfTerm.new(cond: term(node.predicate), thn: term(statements.body.first), els: term(elsNode))
      when node.is_a?(Prism::IntegerNode)
        NumberTerm.new(n: node.value)
      when node.is_a?(Prism::CallNode)
        leftNode = node.receiver
        raise "Unknown node type" unless leftNode.is_a?(Prism::IntegerNode) && node.name == :+
        rightNode = node.arguments&.arguments&.first or raise "Unknown node type"
        AddTerm.new(left: term(leftNode), right: term(rightNode))
      when node.is_a?(Prism::ParenthesesNode)
        statements = node.body
        raise "Unknown node type" unless statements.is_a?(Prism::StatementsNode)
        bodyNode = statements.body.first or raise "Unknown node type"
        term(bodyNode)
      else
        raise "Unknown node type; node => #{node.class}"
      end
    end
  end
end
