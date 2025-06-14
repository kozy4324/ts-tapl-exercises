# rbs_inline: enabled

require_relative "../parser/parser"
# type Term =
#   | { tag: "true" }
#   | { tag: "false" }
#   | { tag: "if"; cond: Term; thn: Term; els: Term }
#   | { tag: "number"; n: number }
#   | { tag: "add"; left: Term; right: Term };

# @rbs!
#   type typ = { tag: "Boolean" }
#            | { tag: "Number" }

class Checker
  #: (TinyRbParser::Term) -> typ
  def self.typecheck(t)
    case
    when t[:tag] == "true"
      { tag: "Boolean" }
    when t[:tag] == "false"
      { tag: "Boolean" }
    when t[:tag] == "if"
      condTy = typecheck(t[:cond])
      raise "boolean expected" if condTy[:tag] != "Boolean"
      thnTy = typecheck(t[:thn])
      elsTy = typecheck(t[:els])
      raise "then and else have different types" if thnTy[:tag] != elsTy[:tag]
      return thnTy
    when t[:tag] == "number"
      { tag: "Number" }
    when t[:tag] == "add"
      leftTy = typecheck(t[:left])
      raise "number expected" if leftTy[:tag] != "Number"
      rightTy = typecheck(t[:right])
      raise "number expected" if rightTy[:tag] != "Number"
      { tag: "Number" }
    else
      raise "not implemented, term = #{t}"
    end
  end
end
