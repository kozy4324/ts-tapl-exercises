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
    assert_equal(expected, Chapter3::Checker.typecheck(Parser.new(source).parse, {}))
  end
end

def expectThrow(expected_message)
  Proc.new do |source|
    err = assert_raises(RuntimeError) do
      Chapter3::Checker.typecheck(Parser.new(source).parse, {})
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

Deno.test("(x: boolean) => 42", expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Boolean" } }], retType: { tag: "Number" } }));
Deno.test("(x: number) => x", expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } }));
Deno.test("(x: number, y: number) => x + y", expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Number" } }, { name: "y", type: { tag: "Number" } }], retType: { tag: "Number" } }));
Deno.test("(x: number, y: number) => x + z", expectThrow("variable not found"));
Deno.test("( (x: number) => x )(42)", expectResult({ tag: "Number" }));
Deno.test("( (x: number) => x )(true)", expectThrow("argument type mismatch"));
Deno.test("( (x: number) => 42 )(1, 2, 3)", expectThrow("wrong number of arguments"));
Deno.test("(f: (x: number) => number) => 1", expectResult({ tag: "Func", params: [{ name: "f", type: { tag: "Func", params: [{ name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } } }], retType: { tag: "Number" } }));

assert_equal(true, Chapter3::Checker.typeEq({ tag: "Boolean" }, { tag: "Boolean" }))
assert_equal(true, Chapter3::Checker.typeEq({ tag: "Number" }, { tag: "Number" }))
assert_equal(false, Chapter3::Checker.typeEq({ tag: "Boolean" }, { tag: "Number" }))
assert_equal(false, Chapter3::Checker.typeEq({ tag: "Number" }, { tag: "Boolean" }))
assert_equal(true, Chapter3::Checker.typeEq({ tag: "Func", params: [], retType: { tag: "Number" } }, { tag: "Func", params: [], retType: { tag: "Number" } }))
assert_equal(false, Chapter3::Checker.typeEq({ tag: "Func", params: [], retType: { tag: "Number" } }, { tag: "Boolean" }))
assert_equal(false, Chapter3::Checker.typeEq(
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } },
  { tag: "Func", params: [                                       ], retType: { tag: "Number" } }
))
assert_equal(true, Chapter3::Checker.typeEq(
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } },
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } }
))
assert_equal(false, Chapter3::Checker.typeEq(
  { tag: "Func", params: [ { name: "x", type: { tag: "Number"  } }], retType: { tag: "Number" } },
  { tag: "Func", params: [ { name: "x", type: { tag: "Boolean" } }], retType: { tag: "Number" } }
))
assert_equal(false, Chapter3::Checker.typeEq(
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } },
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Boolean" } }
))
assert_equal(true, Chapter3::Checker.typeEq(
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } },
  { tag: "Func", params: [ { name: "y", type: { tag: "Number" } }], retType: { tag: "Number" } }
))
