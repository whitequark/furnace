Insturmentation stream format
=============================

Instrumentation data is produced by Foundry as streams of events dumped
as JSON. A stream corresponds to one function.

Within a function, entities have names. Entity names are always unique.
Entity names may change; in this case, all subsequent references are to be
resolved via updated name.

Entities may refer to types. Types are identified with a number, which is
always unique and does not change.

The root of the stream contains a Function.

Type
----

There are several kinds of Types, disambiguated by the field "kind".

### Void type

{
  "event":       "type",
  "id":          <number>,
  "kind":        "void",
}

Should render as:

    void

### Monotypes

{
  "event":       "type",
  "id":          <number>,
  "kind":        "monotype",
  "name":        <string>
}

Should render as:

    #{name}

### Parametric types

{
  "event":       "type",
  "id":          <number>,
  "kind":        "parametric",
  "name":        <string>,
  "parameters":  <array of Type>
}

Should render as:

    #{name}<#{parameters.map(&:render)}>

Function
--------

{
  "name":        <string>,
  "present":     <Boolean>,
  "events":      <array of Event>
}

### Set arguments

{
  "event":       "set_arguments",
  "arguments":   <array of Argument>
}

### Set return type

{
  "event":       "set_return_type",
  "return_type": <Type>
}

Argument
--------

{
  "name":        <string>,
  "type":        <Type>
}

Should render as:

    #{type} %#{name}

Basic block
-----------

Should render as:

    #{name}:
       #{instructions.map(&:render)}

### Add basic block

{
  "event":       "add_basic_block",
  "name":        <string>
}

### Remove basic block

{
  "event":       "remove_basic_block",
  "name":        <string>
}

### Rename basic block

{
  "event":       "rename_basic_block",
  "name":        <string>,
  "new_name":    <string>
}

Operand
-------

### Constant operand

{
  "kind":        "constant",
  "type":        <Type>,
  "value":       <string>
}

Should render as:

    #{type} #{value}

### Argument operand

{
  "kind":        "argument",
  "name":        <string>
}

Should render as:

    %#{name}

### Instruction operand

{
  "kind":        "instruction",
  "name":        <string>
}

Should render as:

    %#{name}

### Basic block operand

{
  "kind":        "basic_block",
  "name":        <string>
}

Should render as:

    label %#{name}

Presence of an operand of this type should create an edge in the graph.

### Function operand

{
  "kind":        "function",
  "name":        <string>
}

Should render as:

    function "#{name}"

Presence of an operand of this type should create a cross-reference link.

Instruction
-----------

Should render as:

1. If it has non-void type:

    #{type} %#{name} = #{opcode} #{parameters} #{operands}

2. If it has void type:

    #{opcode} #{parameters} #{operands}

If `opcode` is `phi`, render `operands` comma-separated with each operand as:

    #{operand[0]} => #{operand[1]}

Else, render `operands` as comma-separated operands.

### Add instruction

{
  "event":       "add_instruction",
  "name":        <string>,
  "basic_block": <string>,
  "position":    <number>
}

### Update instruction

{
  "event":       "update_instruction",
  "opcode":      <string>,
  "name":        <string>
  "parameters":  <string>
  "operands":    <array>
  "type":        <Type>
}

### Remove instruction

{
  "event":       "remove_instruction",
  "name":        <string>
}

### Rename instruction

{
  "event":       "rename_instruction",
  "name":        <string>,
  "new_name":    <string>
}

Miscellanea
-----------

### Transformation start

{
  "event":      "transform_start",
  "name":        <string>
}