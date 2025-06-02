require_relative "./tiny_rb_parser"

require "minitest"
include Minitest::Assertions

class << self
  attr_accessor :assertions
end
self.assertions = 0

def parse(source)
  Chapter3::TinyRbParser.parse(source)
end

assert_equal(parse('true').class, Chapter3::TinyRbParser::TrueTerm)
assert_equal(parse('false').class, Chapter3::TinyRbParser::FalseTerm)
assert_equal(parse('true ? 1 : 2').class, Chapter3::TinyRbParser::IfTerm)
assert_equal(parse('1').class, Chapter3::TinyRbParser::NumberTerm)
assert_equal(parse('1 + 2').class, Chapter3::TinyRbParser::AddTerm)
assert_equal(parse('(1 + 2)').class, Chapter3::TinyRbParser::AddTerm)
assert_equal(parse('-> { 1 }').class, Chapter3::TinyRbParser::FuncTerm)
assert_equal(parse('->(a) { a }').params.first, { name: "a", type: nil })
assert_equal(parse('->(a) { a }').body.class, Chapter3::TinyRbParser::VarTerm)
assert_equal(parse('-> { 1 }.call').class, Chapter3::TinyRbParser::CallTerm)
assert_equal(parse('-> { 1 }.call').func.class, Chapter3::TinyRbParser::FuncTerm)
assert_equal(parse('-> { 1 }.call').args, [])
assert_equal(parse('(-> { 1 }).call').class, Chapter3::TinyRbParser::CallTerm)
assert_equal(parse('->(a) { a }.call(true)').args.size, 1)
assert_equal(parse('->(a) { a }.call(true)').args.first.class, Chapter3::TinyRbParser::TrueTerm)
assert_equal(parse('->(a, b) { 1 + 2 }.call(1, 2)').args.size, 2)
assert_equal(parse('->(a, b) { 1 + 2 }.call(1, 2)').args[0].class, Chapter3::TinyRbParser::NumberTerm)
assert_equal(parse('->(a, b) { 1 + 2 }.call(1, 2)').args[1].class, Chapter3::TinyRbParser::NumberTerm)
assert_equal(parse('->(a, b) { a + b }.call(1, 2)').class, Chapter3::TinyRbParser::CallTerm)
assert_equal(parse('->(a, b) { a + b }').body.class, Chapter3::TinyRbParser::AddTerm)
assert_equal(parse('->(a, b) { a + b }').body.left.class, Chapter3::TinyRbParser::VarTerm)
assert_equal(parse('->(a, b) { a + b }').body.right.class, Chapter3::TinyRbParser::VarTerm)

assert_equal(parse(<<SOURCE).params.first[:type], { tag: "Boolean" })
#: (bool) -> void
->(a) { a }
SOURCE

assert_equal(parse(<<SOURCE).params.first[:type], { tag: "Number" })
#: (Integer) -> void
->(a) { a }
SOURCE

assert_equal(parse(<<SOURCE).params.first[:type], { tag: "Func", params: [], retType: nil })
#: ( ^() -> void ) -> void
->(a) { a }
SOURCE
