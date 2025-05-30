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

    #: (Chapter3::typ, Chapter3::typ) -> bool
    def self.typeEq(ty1, ty2)
      case ty2[:tag]
      when "Boolean"
        ty1[:tag] == "Boolean"
      when "Number"
        ty1[:tag] == "Number"
      when "Func"
        return false if ty1[:tag] != "Func"
        return false if ty1[:params].size != ty2[:params].size
        return false if ty1[:params].zip(ty2[:params]).any? { |p1, p2| !typeEq(p1[:type], p2[:type])} # steep:ignore
        return false unless typeEq(ty1[:retType], ty2[:retType]) # steep:ignore
        true
      end
    end
  end
end
