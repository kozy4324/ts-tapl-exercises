# rbs_inline: enabled

require_relative "../parser/parser"
# @rbs!
#   type term = { tag: "true" }
#             | { tag: "false" }
#             | { tag: "if", cond: term, thn: term, els: term }
#             | { tag: "number", n: Integer }
#             | { tag: "add", left: term, right: term }

# @rbs!
#   type typ = { tag: "Boolean" }
#            | { tag: "Number" }

class Checker
  #: (term) -> typ
  def self.typecheck(t)
    case
    when t[:tag] == "true"
      { tag: "Boolean" }
    when t[:tag] == "false"
      { tag: "Boolean" }
    when t[:tag] == "if"
      cond = t[:cond] #: term
      thn = t[:thn] #: term
      els = t[:els] #: term
      condTy = typecheck(cond)
      raise "boolean expected" if condTy[:tag] != "Boolean"
      thnTy = typecheck(thn)
      elsTy = typecheck(els)
      raise "then and else have different types" if thnTy[:tag] != elsTy[:tag]
      return thnTy
    when t[:tag] == "number"
      { tag: "Number" }
    when t[:tag] == "add"
      left = t[:left] #: term
      right = t[:right] #: term
      leftTy = typecheck(left)
      raise "number expected" if leftTy[:tag] != "Number"
      rightTy = typecheck(right)
      raise "number expected" if rightTy[:tag] != "Number"
      { tag: "Number" }
    else
      raise "not implemented, term = #{t}"
    end
  end
end
