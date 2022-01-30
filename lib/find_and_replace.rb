require 'syntax_tree'
require 'byebug'

source = <<-RUBY
class A
  def a
    [Object.new, Object.new].sum { |o| o.object_id }
  end
end

class B
  class << self
    def b
      values = [Object.new, Object.new]
      values.sum do |v|
        v.object_id
      end
    end
  end
end
RUBY

program = SyntaxTree.parse(source)


def traverse(node, parent = nil, &block)
  block.call node, parent
  byebug if node.child_nodes.any?(&:nil?)
  node.child_nodes.compact.each { |n| traverse(n, node, &block) }
end

source_for_substitution = SyntaxTree.parse("a(0)")

arg_substituion = source_for_substitution.statements.body.first.arguments

traverse(program) do |node, parent|
  next unless node.is_a?(SyntaxTree::Call) && node.message.value == "sum"

  node.instance_variable_set(:@arguments, arg_substituion)
end


output = []

formatter = SyntaxTree::Formatter.new(source, output)
program.format(formatter)

formatter.flush
pp output.join

