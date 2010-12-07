# A visitor for checking that all nodes are properly nested.
class Sass::Tree::Visitors::CheckNesting < Sass::Tree::Visitors::Base
  protected

  def visit(node)
    if error = @parent && (
        try_send("invalid_#{node_name @parent}_child?", @parent, node) ||
        try_send("invalid_#{node_name node}_parent?", @parent, node))
      raise Sass::SyntaxError.new(error)
    end
    super
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:filename => node.filename, :line => node.line)
    raise e
  end

  def visit_children(parent)
    old_parent = @parent
    @parent = parent unless is_any_of?(parent, 
      Sass::Tree::EachNode, Sass::Tree::ForNode, Sass::Tree::IfNode,
      Sass::Tree::ImportNode, Sass::Tree::MixinNode, Sass::Tree::WhileNode)
    super
  ensure
    @parent = old_parent
  end

  def visit_root(node)
    yield
  rescue Sass::SyntaxError => e
    e.sass_template ||= node.template
    raise e
  end

  def visit_import(node)
    yield
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:filename => node.children.first.filename)
    e.add_backtrace(:filename => node.filename, :line => node.line)
    raise e
  end

  def invalid_charset_parent?(parent, child)
    "@charset may only be used at the root of a document." unless parent.is_a?(Sass::Tree::RootNode)
  end

  def invalid_extend_parent?(parent, child)
    unless is_any_of?(parent, Sass::Tree::RuleNode, Sass::Tree::MixinDefNode)
      "Extend directives may only be used within rules."
    end
  end

  def invalid_function_parent?(parent, child)
    "Functions may only be defined at the root of a document." unless parent.is_a?(Sass::Tree::RootNode)
  end

  def invalid_function_child?(parent, child)
    unless is_any_of?(child,
        Sass::Tree::CommentNode, Sass::Tree::DebugNode, Sass::Tree::EachNode,
        Sass::Tree::ForNode, Sass::Tree::IfNode, Sass::Tree::ReturnNode,
        Sass::Tree::VariableNode, Sass::Tree::WarnNode, Sass::Tree::WhileNode)
      "Functions can only contain variable declarations and control directives."
    end
  end

  def invalid_import_parent?(parent, child)
    "Import directives may only be used at the root of a document." unless parent.is_a?(Sass::Tree::RootNode)
  end

  def invalid_mixindef_parent?(parent, child)
    "Mixins may only be defined at the root of a document." unless parent.is_a?(Sass::Tree::RootNode)
  end

  def invalid_prop_child?(parent, child)
    unless is_any_of?(child, Sass::Tree::CommentNode, Sass::Tree::PropNode)
      "Illegal nesting: Only properties may be nested beneath properties."
    end
  end

  def invalid_prop_parent?(parent, child)
    unless is_any_of?(parent,
        Sass::Tree::RuleNode, Sass::Tree::PropNode,
        Sass::Tree::MixinDefNode, Sass::Tree::DirectiveNode)
      "Properties are only allowed within rules, directives, or other properties." + child.pseudo_class_selector_message
    end
  end

  def invalid_return_parent?(parent, child)
    "@return may only be used within a function." unless parent.is_a?(Sass::Tree::FunctionNode)
  end

  private

  def is_any_of?(val, *classes)
    classes.any? {|c| val.is_a?(c)}
  end

  def try_send(method, *args, &block)
    return unless respond_to?(method)
    send(method, *args, &block)
  end
end
