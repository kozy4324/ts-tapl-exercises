require_relative "./arith"

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
    assert_equal(expected, Checker.typecheck(TinyRbParser.parse(source)))
  end
end

def expectThrow(expected_message)
  Proc.new do |source|
    err = assert_raises(RuntimeError) do
      Checker.typecheck(TinyRbParser.parse(source))
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
