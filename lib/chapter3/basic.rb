# rbs_inline: enabled

require_relative "../parser/parser"

module Chapter3
  class Checker
    #: (term, typeEnv) -> typ
    def self.typecheck(t, tyEnv)
      case
      when t[:tag] == "true"
        { tag: "Boolean" }
      when t[:tag] == "false"
        { tag: "Boolean" }
      when t[:tag] == "if"
        condTy = typecheck(t[:cond], tyEnv)
        raise "boolean expected" if condTy[:tag] != "Boolean"
        thnTy = typecheck(t[:thn], tyEnv)
        elsTy = typecheck(t[:els], tyEnv)
        raise "then and else have different types" if thnTy[:tag] != elsTy[:tag]
        return thnTy
      when t[:tag] == "number"
        { tag: "Number" }
      when t[:tag] == "add"
        leftTy = typecheck(t[:left], tyEnv)
        raise "number expected" if leftTy[:tag] != "Number"
        rightTy = typecheck(t[:right], tyEnv)
        raise "number expected" if rightTy[:tag] != "Number"
        { tag: "Number" }
      when t[:tag] == "var"
        raise "variable not found" unless tyEnv.key? t[:name]
        tyEnv[t[:name]]
      when t[:tag] == "func"
        newTyEnv = tyEnv.dup
        t[:params].each do |p|
          newTyEnv[p[:name]] = p[:type] unless p[:type].nil?
        end
        { tag: "Func", params: t[:params], retType: typecheck(t[:body], newTyEnv) }
      when t[:tag] == "call"
        funcTy = typecheck(t[:func], tyEnv)
        raise "function type expected" unless funcTy[:tag] == "Func"
        # funcTy が FuncType であることが自明だが steep は narrowing できないパターン
        raise "wrong number of arguments" if funcTy[:params].size != t[:args].size
        raise "argument type mismatch" if funcTy[:params].zip(t[:args]).any? { |param, argTerm| !typeEq(param[:type], typecheck(argTerm, tyEnv))} # steep:ignore
        retType = funcTy[:retType]
        raise "never raise..." if retType.is_a?(String)
        raise "return type declaration is required" if retType.nil?
        retType
      else
        raise "not implemented"
      end
    end

    #: (typ, typ) -> bool
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
