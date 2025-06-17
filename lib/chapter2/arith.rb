# rbs_inline: enabled

require_relative "../parser/parser"

class Checker
  #: (Chapter3::term) -> untyped
  def self.typecheck(t)
    case
    when t[:tag] == "true"
      { tag: "Boolean" }
    when t[:tag] == "false"
      { tag: "Boolean" }
    when t[:tag] == "if"
      cond = t[:cond] #: Chapter3::term
      thn = t[:thn] #: Chapter3::term
      els = t[:els] #: Chapter3::term
      condTy = typecheck(cond)
      raise "boolean expected" if condTy[:tag] != "Boolean"
      thnTy = typecheck(thn)
      elsTy = typecheck(els)
      raise "then and else have different types" if thnTy[:tag] != elsTy[:tag]
      return thnTy
    when t[:tag] == "number"
      { tag: "Number" }
    when t[:tag] == "add"
      left = t[:left] #: Chapter3::term
      right = t[:right] #: Chapter3::term
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
