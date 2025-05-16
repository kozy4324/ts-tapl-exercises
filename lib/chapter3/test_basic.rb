require_relative "./basic"

require "minitest"
include Minitest::Assertions

class << self
  attr_accessor :assertions
end
self.assertions = 0

# TSのテストコードをそのまま貼り付けられるようにする
class Deno
  def self.test(source, proc)
    proc.call(source)
  end
end

def expectResult(expected)
  Proc.new do |source|
    assert_equal(expected, Chapter3::Checker.typecheck(Chapter3::TinyRbParser.parse(source)))
  end
end

def expectThrow(expected_message)
  Proc.new do |source|
    err = assert_raises(RuntimeError) do
      Chapter3::Checker.typecheck(Chapter3::TinyRbParser.parse(source))
    end
    assert_equal(expected_message, err.message)
  end
end

Deno.test("1 + 2", expectResult({ tag: "Number" }));
Deno.test("1 + true", expectThrow("number expected"));
Deno.test("1 + (2 + 3)", expectResult({ tag: "Number" }));
Deno.test("true ? 1 : 2", expectResult({ tag: "Number" }));
Deno.test("true ? false : true", expectResult({ tag: "Boolean" }));
Deno.test("1 ? 2 : 3", expectThrow("boolean expected"));
Deno.test("true ? 1 : true", expectThrow("then and else have different types"));
Deno.test("true ? (1 + 2) : (3 + (false ? 4 : 5))", expectResult({ tag: "Number" }));

# Deno.test("->(x) { 42 }", expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Boolean" } }], retType: { tag: "Number" } }));
# Deno.test("->(x) { x }", expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } }));
# Deno.test("->(x, y) { x + y }", expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Number" } }, { name: "y", type: { tag: "Number" } }], retType: { tag: "Number" } }));
# Deno.test("->(x, y) { x + z }", expectThrow("variable not found"));
# Deno.test("(->(x) { x }).call(42)", expectResult({ tag: "Number" }));
# Deno.test("(->(x) { x }).call(true)", expectThrow("argument type mismatch"));
# Deno.test("(->(x) { 42 }).call(1, 2, 3);", expectThrow("wrong number of arguments"));
# Deno.test("->(f) { 1 }", expectResult({ tag: "Func", params: [{ name: "f", type: { tag: "Func", params: [{ name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } } }], retType: { tag: "Number" } }));
