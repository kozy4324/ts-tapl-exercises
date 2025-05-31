# rbs_inline: enabled

require_relative "./tiny_rb_parser"

# @rbs!
#   type Chapter3::typeEnv = Hash[String, Chapter3::typ]

module Chapter3
  class Checker
    #: (Chapter3::TinyRbParser::Term, Chapter3::typeEnv) -> Chapter3::typ
    def self.typecheck(t, tyEnv)
      case
      when t.is_a?(TinyRbParser::TrueTerm)
        { tag: "Boolean" }
      when t.is_a?(TinyRbParser::FalseTerm)
        { tag: "Boolean" }
      when t.is_a?(TinyRbParser::IfTerm)
        condTy = typecheck(t.cond, tyEnv)
        raise "boolean expected" if condTy[:tag] != "Boolean"
        thnTy = typecheck(t.thn, tyEnv)
        elsTy = typecheck(t.els, tyEnv)
        raise "then and else have different types" if thnTy[:tag] != elsTy[:tag]
        return thnTy
      when t.is_a?(TinyRbParser::NumberTerm)
        { tag: "Number" }
      when t.is_a?(TinyRbParser::AddTerm)
        leftTy = typecheck(t.left, tyEnv)
        raise "number expected" if leftTy[:tag] != "Number"
        rightTy = typecheck(t.right, tyEnv)
        raise "number expected" if rightTy[:tag] != "Number"
        { tag: "Number" }
      when t.is_a?(TinyRbParser::VarTerm)
        raise "variable not found" unless tyEnv.key? t.name
        tyEnv[t.name]
      when t.is_a?(TinyRbParser::FuncTerm)
        newTyEnv = tyEnv.dup
        t.params.each { |p| newTyEnv[p.name] = p.type }
        Chapter3::TinyRbParser.to_typ({ tag: "Func", params: t.params.map {|p| { name: p.name, type: p.type } }, retType: typecheck(t.body, newTyEnv ) })
      when t.is_a?(TinyRbParser::CallTerm)
        funcTy = typecheck(t.func, tyEnv)
        raise "function type expected" unless funcTy[:tag] == "Func"
        raise "wrong number of arguments" if funcTy[:params].size != t.args.size
        raise "argument type mismatch" if funcTy[:params].zip(t.args).any? { |param, argTerm| !typeEq(param[:type], typecheck(argTerm, tyEnv))} # steep:ignore
        Chapter3::TinyRbParser.to_typ funcTy[:retType]
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
