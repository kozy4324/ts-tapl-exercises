# rbs_inline: enabled

require_relative "./tiny_rb_parser"

module Chapter3
  class Checker
    #: (TinyRbParser::Term) -> typ
    def self.typecheck(t)
      case
      when t.is_a?(TinyRbParser::TrueTerm)
        { tag: "Boolean" }
      when t.is_a?(TinyRbParser::FalseTerm)
        { tag: "Boolean" }
      when t.is_a?(TinyRbParser::IfTerm)
        condTy = typecheck(t.cond)
        raise "boolean expected" if condTy[:tag] != "Boolean"
        thnTy = typecheck(t.thn)
        elsTy = typecheck(t.els)
        raise "then and else have different types" if thnTy[:tag] != elsTy[:tag]
        return thnTy
      when t.is_a?(TinyRbParser::NumberTerm)
        { tag: "Number" }
      when t.is_a?(TinyRbParser::AddTerm)
        leftTy = typecheck(t.left)
        raise "number expected" if leftTy[:tag] != "Number"
        rightTy = typecheck(t.right)
        raise "number expected" if rightTy[:tag] != "Number"
        { tag: "Number" }
      # TODO: when t.is_a?(TinyRbParser::VarTerm)
      # TODO: when t.is_a?(TinyRbParser::FuncTerm)
      # TODO: when t.is_a?(TinyRbParser::CallTerm)
      else
        raise "not implemented"
      end
    end
  end
end
