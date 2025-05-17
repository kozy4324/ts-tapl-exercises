# rbs_inline: enabled

require "prism"

# chapter3 で追加される構文
# 変数参照
#   { tag: "var"; name: string }
# 無名関数
#   { tag: "func"; params: Param[]; body: Term }
#   ts
#     (x: number) => x
#   rb
#     ->(x) { x }
# 関数呼び出し
#   { tag: "call"; func: Term; args: Term[] }
#   ts
#     f(1)
#   rb
#     f.call(1)

# @rbs!
#   type Chapter3::typ = { tag: "Boolean" }
#                      | { tag: "Number" }
#                      | { tag: "Func", params: Array[Chapter3::TinyRbParser::Param], body: typ }

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

    class FuncTerm < Term
      attr_accessor :params #: Array[Param]
      attr_accessor :body #: Term
      #: (params: Array[Param], body: Term) -> void
      def initialize(params:, body:)
        @params = params
        @body = body
      end
    end

    class Param
      attr_accessor :name #: String
      attr_accessor :type #: typ
      #: (name: String, type: typ) -> void
      def initialize(name:, type:)
        @name = name
        @type = type
      end
    end

    #: (Prism::node, String) -> String
    def self.retrieve_comment(node, source)
      line = node.location.start_line
      source.split("\n")[line - 2].gsub(/#:/, "").strip
    end

    #: (String) -> Term
    def self.parse(source)
      result = Prism.parse(source) # Prism::ParseResult
      statements = result.value.statements # Prism::StatementsNode
      nodes = statements.body # Array[Prism::node]
      node = nodes.first # Prism::node

      # puts retrieve_comment(node, source)
      term(node, source)
    rescue RuntimeError => e
      raise "#{e.message}; source => #{source}"
    end

    #: (Prism::node, String) -> Term
    def self.term(node, source)
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
        IfTerm.new(cond: term(node.predicate, source), thn: term(statements.body.first, source), els: term(elsNode, source))
      when node.is_a?(Prism::IntegerNode)
        NumberTerm.new(n: node.value)
      when node.is_a?(Prism::CallNode)
        leftNode = node.receiver
        raise "Unknown node type" unless leftNode.is_a?(Prism::IntegerNode) && node.name == :+
        rightNode = node.arguments&.arguments&.first or raise "Unknown node type"
        AddTerm.new(left: term(leftNode, source), right: term(rightNode, source))
      when node.is_a?(Prism::ParenthesesNode)
        statements = node.body
        raise "Unknown node type" unless statements.is_a?(Prism::StatementsNode)
        bodyNode = statements.body.first or raise "Unknown node type"
        term(bodyNode, source)
      when node.is_a?(Prism::LambdaNode)
        statements_node = node.body
        raise "Unknown node type" unless statements_node.is_a?(Prism::StatementsNode)
        statement_node = statements_node.body.first
        if node.parameters.nil?
          FuncTerm.new(params: [], body: term(statement_node, source))
        else
          block_parameters_node = node.parameters
          raise "Unknown node type" unless block_parameters_node.is_a?(Prism::BlockParametersNode)
          paramters_node = block_parameters_node.parameters
          raise "Unknown node type" unless paramters_node.is_a?(Prism::ParametersNode)
          params = paramters_node.requireds.map do |required_paramter_node|
            raise "Unknown node type" unless required_paramter_node.is_a?(Prism::RequiredParameterNode)
            Param.new(name: required_paramter_node.name.to_s, type: { tag: "Number" }) # TODO: 引数の型を解決する
          end
          FuncTerm.new(params: params, body: term(statement_node, source))
        end
      else
        raise "Unknown node type; node => #{node.class}"
      end
    end
  end
end

puts Chapter3::TinyRbParser.parse(<<CODE).inspect
#: (Integer) -> Integer
-> (x) { 1 + 2 }
CODE
