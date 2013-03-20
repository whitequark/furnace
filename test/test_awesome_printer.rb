require_relative 'helper'

describe AwesomePrinter do
  AwesomePrinter.colorize = false

  it 'outputs chunks' do
    AwesomePrinter.new do |p|
      p.text 'foo'
    end.should == 'foo'

    AwesomePrinter.new do |p|
      Integer.to_type.awesome_print(p)
    end.should == '^Integer'

    AwesomePrinter.new do |p|
      p.keyword 'bar'
    end.should == 'bar'
  end

  it 'supports matching by =~' do
    AwesomePrinter.new do |p|
      p.text 'foo'
    end.should =~ /foo/
  end

  it 'ensures space between chunks' do
    AwesomePrinter.new do |p|
      p.text 'foo'
      p.keyword 'doh'
      p.text 'bar'
    end.should == 'foo doh bar'
  end

  it 'adds no space before and after #append' do
    AwesomePrinter.new do |p|
      p.text 'foo'
      p.append 'bar'
      p.text 'baz'
    end.should == 'foobarbaz'
  end

  it 'adds no space after #newline' do
    AwesomePrinter.new do |p|
      p.text 'foo'
      p.newline
      p.text 'bar'
    end.should == "foo\nbar"
  end

  it 'converts objects to chunks with to_s' do
    AwesomePrinter.new do |p|
      p.text :foo
      p.text 1
      p.keyword :bar
    end.should == 'foo 1 bar'
  end

  it 'when nesting, delegates to #awesome_print and then #to_s' do
    with_awesome_print = Object.new.tap do |o|
      def o.awesome_print(p)
        p.text "awesome print"
      end
    end

    with_inspect = Object.new.tap do |o|
      def o.to_s
        "awesome to_s"
      end
    end

    AwesomePrinter.new do |p|
      p.nest with_awesome_print
      p.nest with_inspect
    end.should == 'awesome print awesome to_s'
  end

  it 'prints %names' do
    AwesomePrinter.new do |p|
      p.name 'foo'
    end.should == '%foo'
  end

  it 'prints type variables' do
    a, b = 2.times.map { Type::Variable.new }

    AwesomePrinter.new do |p|
      p.type_variable a
      p.type_variable b
      p.type_variable a
    end.should == '~a ~b ~a'
  end

  it 'prints type variables with passed Annotator' do
    a, b = 2.times.map { Type::Variable.new }

    ann = Type::Variable::Annotator.new
    ann.annotate a

    AwesomePrinter.new(false, ann) do |p|
      p.type_variable b
    end.should == '~b'
  end

  it 'prints collections' do
    AwesomePrinter.new do |p|
      p.collection(%w(a b c))
    end.should == 'abc'

    AwesomePrinter.new do |p|
      p.collection('<', '; ', '>', %w(a b c))
    end.should == '<a; b; c>'
  end

  it 'ensures space before collections' do
    AwesomePrinter.new do |p|
      p.text 'foo'
      p.collection(%w(a b c))
    end.should == 'foo abc'
  end

  it 'prints collections with custom iterator' do
    AwesomePrinter.new do |p|
      p.collection(%w(abc def)) do |e|
        p.text e.reverse
      end
    end.should == 'cbafed'
  end

  it 'chains' do
    AwesomePrinter.new do |p|
      p.append("foo").should == p
      p.text("foo").should == p
      p.newline.should == p
      p.nest("foo").should == p
      p.name("foo").should == p
      p.type("foo").should == p
      p.type_variable(Type::Variable.new).should == p
      p.keyword("foo").should == p
      p.collection(%w(a b)).should == p
    end
  end

  it 'adds colors if requested' do
    AwesomePrinter.new(true) do |p|
      p.keyword :bar
    end.should == "\e[1;37mbar\e[0m"
  end
end
