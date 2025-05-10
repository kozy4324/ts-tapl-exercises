# rbs_inline: enabled

require_relative "./tiny_rb_parser"

puts TinyRbParser.parse("true").inspect
puts TinyRbParser.parse("false").inspect
puts TinyRbParser.parse("true ? 1 : 2").inspect
puts TinyRbParser.parse("3").inspect
puts TinyRbParser.parse("4 + 5").inspect

term = TinyRbParser.parse("true ? 1 : 2")
if term.is_a? TinyRbParser::IfTerm
  puts term.inspect
end