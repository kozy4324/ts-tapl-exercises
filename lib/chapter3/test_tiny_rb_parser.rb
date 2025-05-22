require_relative "./tiny_rb_parser"

require "minitest"
include Minitest::Assertions

class << self
  attr_accessor :assertions
end
self.assertions = 0

def assert_parse_result(source, cls)
  assert_equal(Chapter3::TinyRbParser.parse(source).class, cls)
end

assert_parse_result('true', Chapter3::TinyRbParser::TrueTerm)
assert_parse_result('false', Chapter3::TinyRbParser::FalseTerm)
assert_parse_result('true ? 1 : 2', Chapter3::TinyRbParser::IfTerm)
assert_parse_result('1', Chapter3::TinyRbParser::NumberTerm)
assert_parse_result('1 + 2', Chapter3::TinyRbParser::AddTerm)
assert_parse_result('-> { 1 }', Chapter3::TinyRbParser::FuncTerm)
