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
    assert_equal(expected, Chapter3::Checker.typecheck(Chapter3::TinyRbParser.parse(source), {}))
  end
end

def expectThrow(expected_message)
  Proc.new do |source|
    err = assert_raises(RuntimeError) do
      Chapter3::Checker.typecheck(Chapter3::TinyRbParser.parse(source), {})
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

Deno.test(<<SOURCE, expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Boolean" } }], retType: { tag: "Number" } }));
#: (bool) -> void
->(x) { 42 }
SOURCE

Deno.test(<<SOURCE, expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } }));
#: (Integer) -> void
->(x) { x }
SOURCE

Deno.test(<<SOURCE, expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Number" } }, { name: "y", type: { tag: "Number" } }], retType: { tag: "Number" } }));
#: (Integer, Integer) -> void
->(x, y) { x + y }
SOURCE

Deno.test(<<SOURCE, expectThrow("variable not found"));
#: (Integer, Integer) -> void
->(x, y) { x + z }
SOURCE

# Deno.test(<<SOURCE, expectResult({ tag: "Number" }));
# #: (Integer) -> void
# (->(x) { x }).call(42)
# SOURCE

# Deno.test(<<SOURCE, expectThrow("argument type mismatch"));
# #: (Integer) -> void
# (->(x) { x }).call(true)
# SOURCE

# Deno.test(<<SOURCE, expectThrow("wrong number of arguments"));
# #: (Integer) -> void
# (->(x) { 42 }).call(1, 2, 3)
# SOURCE

# Deno.test(<<SOURCE, expectResult({ tag: "Func", params: [{ name: "f", type: { tag: "Func", params: [{ name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } } }], retType: { tag: "Number" } }));
# #: ( ^(Integer) -> void ) -> void
# ->(f) { 1 }
# SOURCE

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
