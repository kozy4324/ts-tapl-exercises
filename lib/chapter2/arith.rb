# rbs_inline: enabled

require "prism"

# @rbs!
#   type term = { tag: "true" }
#             | { tag: "false" }
#             | { tag: "if", cond: term, thn: term, els: term }
#             | { tag: "number", n: Integer }
#             | { tag: "add", left: term, right: term }

class TinyRbParser
  #: (String) -> term
  def self.parse(source)
    result = Prism.parse(source) # Prism::ParseResult
    statements = result.value.statements # Prism::StatementsNode
    nodes = statements.body # Array[Prism::node]
    node = nodes.first # Prism::node

    term(node)
  end

  #: (Prism::node) -> term
  def self.term(node)
    raise "Unknown node type" if node.nil?

    case
    when node.is_a?(Prism::TrueNode)
      { tag: "true" }
    when node.is_a?(Prism::FalseNode)
      { tag: "false" }
    when node.is_a?(Prism::IfNode)
      statements = node.statements or raise "Unknown node type"
      subsequent = node.subsequent or raise "Unknown node type"
      raise "Unknown node type" unless subsequent.is_a?(Prism::ElseNode)
      elsNode = subsequent.statements&.body&.first or raise "Unknown node type"
      { tag: "if", cond: term(node.predicate), thn: term(statements.body.first), els: term(elsNode) }
    when node.is_a?(Prism::IntegerNode)
      { tag: "number", n: node.value }
    when node.is_a?(Prism::CallNode)
      receiver = node.receiver
      if receiver.is_a?(Prism::IntegerNode) && node.name == :+
        rightNode = node.arguments&.arguments&.first or raise "Unknown node type"
        { tag: "add", left: term(receiver), right: term(rightNode) }
      else
        raise "Unknown node type"
      end
    else
      raise "Unknown node type"
    end
  end
end

puts TinyRbParser.parse("true")
puts TinyRbParser.parse("false")
puts TinyRbParser.parse("true ? 1 : 2")
puts TinyRbParser.parse("3")
puts TinyRbParser.parse("4 + 5")
