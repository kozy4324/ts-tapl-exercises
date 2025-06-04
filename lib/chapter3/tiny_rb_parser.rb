# rbs_inline: enabled

require "prism"
require "rbs"

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
#                      | { tag: "Func", params: Array[Chapter3::typ | nil], retType: Chapter3::typ | nil }

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

    class VarTerm < Term
      attr_accessor :name #: String
      #: (params: name: String) -> void
      def initialize(name:)
        @name = name
      end
    end

    class FuncTerm < Term
      attr_accessor :params #: Array[{ name: String, type: typ | nil }]
      attr_accessor :body #: Term
      #: (params: Array[{ name: String, type: typ | nil }], body: Term) -> void
      def initialize(params:, body:)
        @params = params
        @body = body
      end
    end

    class CallTerm < Term
      attr_accessor :func #: Term
      attr_accessor :args #: Array[Term]
      #: (func: Term, args: Array[Term]) -> void
      def initialize(func:, args:)
        @func = func
        @args = args
      end
    end

    #: (Integer, Prism::ParseResult) -> { param_types: Array[Chapter3::typ], return_type: Chapter3::typ | nil }
    def self.type_def(node_location_start_line, parse_result)
      return { param_types: [], return_type: nil } if parse_result.comments.empty?
      inline_comment = parse_result.comments.find {|c| c.location.start_line == node_location_start_line - 1}
      return { param_types: [], return_type: nil } if inline_comment.nil?
      comment_source = parse_result.source.source[inline_comment.location.start_offset, inline_comment.location.length]
      return { param_types: [], return_type: nil } if comment_source.nil?
      annotation = RBS::Parser.parse_inline_leading_annotation(comment_source[1...], 0...) # steep:ignore
      return { param_types: [], return_type: nil } unless annotation.is_a? RBS::AST::Ruby::Annotations::ColonMethodTypeAnnotation # steep:ignore
      method_type = annotation.method_type.type
      return { param_types: [], return_type: nil } unless method_type.is_a? RBS::Types::Function
      params = method_type.required_positionals
      {
        param_types: params.map do |param|
          case param.type.to_s
          when "bool"
            { tag: "Boolean" }
          when "Integer"
            { tag: "Number" }
          when /^\^.*/
            param_type_def = type_def(2, Prism.parse("#: #{param.type.to_s[1..]}"))
            {
              tag: "Func",
              params: param_type_def[:param_types],
              retType: param_type_def[:return_type]
            }
          else
            raise "Unknown annotation type"
          end
        end,
        return_type: case method_type.return_type.to_s
                    when "void"
                      nil
                    when "bool"
                      { tag: "Boolean" }
                    when "Integer"
                      { tag: "Number" }
                    when /^\^.*/
                      param_type_def = type_def(2, Prism.parse("#: #{method_type.return_type.to_s[1..]}"))
                      {
                        tag: "Func",
                        params: param_type_def[:param_types],
                        retType: param_type_def[:return_type]
                      }
                    else
                      raise "Unknown annotation type"
                    end
      }
    end

    #: (String) -> Term
    def self.parse(source)
      result = Prism.parse(source) # Prism::ParseResult
      statements = result.value.statements # Prism::StatementsNode
      nodes = statements.body # Array[Prism::node]
      node = nodes.first # Prism::node

      term(node, result)
    rescue RuntimeError => e
      raise "#{e.message}; source => #{source}"
    end

    #: (Prism::node, Prism::ParseResult) -> Term
    def self.term(node, result)
      case
      when node.is_a?(Prism::TrueNode)
        TrueTerm.new
      when node.is_a?(Prism::FalseNode)
        FalseTerm.new
      when node.is_a?(Prism::IfNode)
        statements = node.statements or raise "Unknown node type; node => #{node.class}"
        subsequent = node.subsequent or raise "Unknown node type; node => #{node.class}"
        raise "Unknown node type; node => #{node.class}" unless subsequent.is_a?(Prism::ElseNode)
        elsNode = subsequent.statements&.body&.first or raise "Unknown node type; node => #{node.class}"
        IfTerm.new(cond: term(node.predicate, result), thn: term(statements.body.first, result), els: term(elsNode, result))
      when node.is_a?(Prism::IntegerNode)
        NumberTerm.new(n: node.value)
      when node.is_a?(Prism::CallNode)
        leftNode = node.receiver
        if leftNode.nil?
          # Rubyにおいて未定義変数の参照っぽい記述は self.x というメソッド呼び出しなので AST としては CallNode になる
          # VarTerm として処理してみる
          return VarTerm.new(name: node.name)
        end
        raise "Unknown node type; node => #{node.class}" unless node.name == :+ || node.name == :call
        if node.name == :+
          rightNode = node.arguments&.arguments&.first or raise "Unknown node type; node => #{node.class}"
          AddTerm.new(left: term(leftNode, result), right: term(rightNode, result))
        else
          args = node.arguments&.arguments || []
          CallTerm.new(func: term(leftNode, result), args: args.map { term(_1, result) })
        end
      when node.is_a?(Prism::ParenthesesNode)
        statements = node.body
        raise "Unknown node type; node => #{node.class}" unless statements.is_a?(Prism::StatementsNode)
        bodyNode = statements.body.first or raise "Unknown node type; node => #{node.class}"
        term(bodyNode, result)
      when node.is_a?(Prism::LocalVariableReadNode)
        VarTerm.new(name: node.name.to_s)
      when node.is_a?(Prism::LambdaNode)
        func_type_def = type_def(node.location.start_line, result)
        statements_node = node.body
        raise "Unknown node type; node => #{node.class}" unless statements_node.is_a?(Prism::StatementsNode)
        statement_node = statements_node.body.first
        if node.parameters.nil?
          FuncTerm.new(params: [], body: term(statement_node, result))
        else
          block_parameters_node = node.parameters
          raise "Unknown node type; node => #{node.class}" unless block_parameters_node.is_a?(Prism::BlockParametersNode)
          paramters_node = block_parameters_node.parameters
          raise "Unknown node type; node => #{node.class}" unless paramters_node.is_a?(Prism::ParametersNode)
          FuncTerm.new(
            params: paramters_node.requireds.map.with_index.map do |required_paramter_node, idx|
              raise "Unknown node type; node => #{node.class}" unless required_paramter_node.is_a?(Prism::RequiredParameterNode)
              { name: required_paramter_node.name.to_s, type: func_type_def[:param_types][idx] }
            end,
            body: term(statement_node, result)
          )
        end
      else
        raise "Unknown node type; node => #{node.class}"
      end
    end
  end
end
