# Settings Reference

## alignment.consecutive.assignments

Type: _boolean_

Default: **false**

When true, cfformat will attempt to align consecutive variable assignments, named function call arguments, and struct key value pairs.

```cfc
// alignment.consecutive.assignments: true
var a  = 1;
var ab = 2;

// alignment.consecutive.assignments: false
var a = 1;
var ab = 2;
```

## alignment.consecutive.params

Type: _boolean_

Default: **false**

When true, cfformat will attempt to align the attributes of consecutive params.

```cfc
// alignment.consecutive.params: true
param name="a"       type="string";
param name="abcdefg" type="string";

// alignment.consecutive.params: false
param name="a" type="string";
param name="abcdefg" type="string";
```

## alignment.consecutive.properties

Type: _boolean_

Default: **false**

When true, cfformat will attempt to align the attributes of consecutive properties.

```cfc
// alignment.consecutive.properties: true
property name="requestService" inject="coldbox:requestService";
property name="log"            inject="logbox:logger:{this}";

// alignment.consecutive.properties: false
property name="requestService" inject="coldbox:requestService";
property name="log" inject="logbox:logger:{this}";
```

## array.empty_padding

Type: _boolean_

Default: **false**

When true, empty arrays are padded with a space.

```cfc
// array.empty_padding: true
myArray = [ ];

// array.empty_padding: false
myArray = [];
```

## array.multiline.element_count

Type: _integer_

Default: **4**

When an array has this number of elements or more, print it onto multiple lines.


## array.multiline.leading_comma

Type: _boolean_

Default: **false**

Whether to use a leading comma when an array is printed on multiple lines.

```cfc
// array.multiline.leading_comma: true
myArray = [
      1
    , 2
    , 3
    , 4
];

// array.multiline.leading_comma: false
myArray = [
    1,
    2,
    3,
    4
];
```

## array.multiline.leading_comma.padding

Type: _boolean_

Default: **true**

Whether to insert a space after leading commas when an array is printed on multiple lines.

```cfc
// array.multiline.leading_comma.padding: true
myArray = [
      1
    , 2
    , 3
    , 4
];

// array.multiline.leading_comma.padding: false
myArray = [
     1
    ,2
    ,3
    ,4
];
```

## array.multiline.min_length

Type: _integer_

Default: **40**

No matter how many elements an array has, if it is shorter than this length, keep it on one line.


## array.padding

Type: _boolean_

Default: **false**

When true, non-empty arrays are padded with spaces.

```cfc
// array.padding: true
myArray = [ 1, 2 ];

// array.padding: false
myArray = [1, 2];
```

## binary_operators.padding

Type: _boolean_

Default: **true**

Whether to pad binary operators with spaces.

```cfc
// binary_operators.padding: true
a = 1 + 2;

// binary_operators.padding: false
a=1+2;
```

## brackets.padding

Type: _boolean_

Default: **false**

When true, bracketed accessors are padded with spaces.

```cfc
// brackets.padding: true
a[ 'mykey' ][ 1 ] = 7;

// brackets.padding: false
a['mykey'][1] = 7;
```

## comment.asterisks

Type: _string_

Values: [**"align"**, "indent", "ignored"]

When enabled, if every line after the first of a block comment starts with a `*`, they will be aligned. Setting this to "ignored" means no alignment will be done.

```cfc
// comment.asterisks: "align"
{
    /**
     * a comment
     */
}

// comment.asterisks: "indent"
{
    /**
    * a comment
    */
}

// comment.asterisks: "ignored"
{
    /**
      * a comment
    */
}
```

## for_loop_semicolons.padding

Type: _boolean_

Default: **true**

When true, insert a space after for loop semicolons.

```cfc
// for_loop_semicolons.padding: true
for (var i = 0; i < 10; i++) {
}

// for_loop_semicolons.padding: false
for (var i = 0;i < 10;i++) {
}
```

## function_anonymous.empty_padding

Type: _boolean_

Default: **false**

When true, pad anonymous function declarations that have no parameters with a space.

```cfc
// function_anonymous.empty_padding: true
function( ) {
}

// function_anonymous.empty_padding: false
function() {
}
```

## function_anonymous.group_to_block_spacing

Type: _string_

Values: [**"spaced"**, "compact", "newline"]

How to space from the anonymous function parameters to the function block.

```cfc
// function_anonymous.group_to_block_spacing: "spaced"
function() {
}

// function_anonymous.group_to_block_spacing: "compact"
function(){
}

// function_anonymous.group_to_block_spacing: "newline"
function()
{
}
```

## function_anonymous.multiline.element_count

Type: _integer_

Default: **4**

When an anonymous function declaration has this number of parameters, split them onto multiple lines.


## function_anonymous.multiline.leading_comma

Type: _boolean_

Default: **false**

Whether to use a leading comma when anonymous function declaration parameters are printed on multiple lines.

```cfc
// function_anonymous.multiline.leading_comma: true
function(
      a
    , b
    , c
    , d
) {
}

// function_anonymous.multiline.leading_comma: false
function(
    a,
    b,
    c,
    d
) {
}
```

## function_anonymous.multiline.leading_comma.padding

Type: _boolean_

Default: **true**

Whether to insert a space after leading commas when anonymous function declaration parameters are printed on multiple lines.

```cfc
// function_anonymous.multiline.leading_comma.padding: true
function(
      a
    , b
    , c
    , d
) {
}

// function_anonymous.multiline.leading_comma.padding: false
function(
     a
    ,b
    ,c
    ,d
) {
}
```

## function_anonymous.multiline.min_length

Type: _integer_

Default: **40**

No matter how many parameters an anonymous function declaration has, if they can be printed in this many columns or less, keep them on one line.


## function_anonymous.padding

Type: _boolean_

Default: **false**

Whether to pad non-empty anonymous function declarations with spaces.

```cfc
// function_anonymous.padding: true
function( a, b ) {
}

// function_anonymous.padding: false
function(a, b) {
}
```

## function_call.casing.builtin

Type: _string_

Values: [**"cfdocs"**, "pascal", "ignored"]

Formats builtin function call casing. The default is to match cfdocs.org data. An alternative is to always capitalize the first letter (pascal). Set this setting to "ignored" to leave casing as is.

```cfc
// function_call.casing.builtin: "cfdocs"
arrayAppend(myarray, 1);

// function_call.casing.builtin: "pascal"
ArrayAppend(myarray, 1);

// function_call.casing.builtin: "ignored"
ARRAYAPPEND(myarray, 1);
```

## function_call.casing.userdefined

Type: _string_

Values: [**"ignored"**, "camel", "pascal"]

Formats user defined function call casing. The default is to leave as is (this is set to "ignored"). Alternatives are to always capitalize the first letter (pascal), or always lower case it (camel).

```cfc
// function_call.casing.userdefined: "ignored"
myFunc();

// function_call.casing.userdefined: "camel"
myFunc();

// function_call.casing.userdefined: "pascal"
MyFunc();
```

## function_call.empty_padding

Type: _boolean_

Default: **false**

When true, function calls with no arguments are padded with a space.

```cfc
// function_call.empty_padding: true
myFunc( );

// function_call.empty_padding: false
myFunc();
```

## function_call.multiline.element_count

Type: _integer_

Default: **4**

When a function call has this number of arguments, split them onto multiple lines.


## function_call.multiline.leading_comma

Type: _boolean_

Default: **false**

Whether to use a leading comma when function call arguments are printed on multiple lines.

```cfc
// function_call.multiline.leading_comma: true
myFunc(
      1
    , 2
    , 3
    , 4
);

// function_call.multiline.leading_comma: false
myFunc(
    1,
    2,
    3,
    4
);
```

## function_call.multiline.leading_comma.padding

Type: _boolean_

Default: **true**

Whether to insert a space after leading commas when function call arguments are printed on multiple lines.

```cfc
// function_call.multiline.leading_comma.padding: true
myFunc(
      1
    , 2
    , 3
    , 4
);

// function_call.multiline.leading_comma.padding: false
myFunc(
     1
    ,2
    ,3
    ,4
);
```

## function_call.multiline.min_length

Type: _integer_

Default: **40**

No matter how many arguments a function call has, if they can be printed inline in this many columns or less, keep them on one line.


## function_call.padding

Type: _boolean_

Default: **false**

Whether to pad function call arguments with spaces.

```cfc
// function_call.padding: true
myFunc( 1, 2 );

// function_call.padding: false
myFunc(1, 2);
```

## function_declaration.empty_padding

Type: _boolean_

Default: **false**

When true, pad function declarations that have no parameters with a space.

```cfc
// function_declaration.empty_padding: true
function example( ) {
}

// function_declaration.empty_padding: false
function example() {
}
```

## function_declaration.group_to_block_spacing

Type: _string_

Values: [**"spaced"**, "compact", "newline"]

How to space from the function parameters to the function block.

```cfc
// function_declaration.group_to_block_spacing: "spaced"
function example() {
}

// function_declaration.group_to_block_spacing: "compact"
function example(){
}

// function_declaration.group_to_block_spacing: "newline"
function example()
{
}
```

## function_declaration.multiline.element_count

Type: _integer_

Default: **4**

When a function declaration has this number of parameters, split them onto multiple lines.


## function_declaration.multiline.leading_comma

Type: _boolean_

Default: **false**

Whether to use a leading comma when function declaration parameters are printed on multiple lines.

```cfc
// function_declaration.multiline.leading_comma: true
function example(
      a
    , b
    , c
    , d
) {
}

// function_declaration.multiline.leading_comma: false
function example(
    a,
    b,
    c,
    d
) {
}
```

## function_declaration.multiline.leading_comma.padding

Type: _boolean_

Default: **true**

Whether to insert a space after leading commas when function declaration parameters are printed on multiple lines.

```cfc
// function_declaration.multiline.leading_comma.padding: true
function example(
      a
    , b
    , c
    , d
) {
}

// function_declaration.multiline.leading_comma.padding: false
function example(
     a
    ,b
    ,c
    ,d
) {
}
```

## function_declaration.multiline.min_length

Type: _integer_

Default: **40**

No matter how many parameters a function declaration has, if they can be printed in this many columns or less, keep them on one line.


## function_declaration.padding

Type: _boolean_

Default: **false**

Whether to pad non-empty function declarations with spaces.

```cfc
// function_declaration.padding: true
function example( a, b ) {
}

// function_declaration.padding: false
function example(a, b) {
}
```

## indent_size

Type: _integer_

Default: **4**

Each indent level or tab is equivalent to this many spaces.

```cfc
// indent_size: 4
do {
    myFunc();
}

// indent_size: 2
do {
  myFunc();
}
```

## keywords.block_to_keyword_spacing

Type: _string_

Values: [**"spaced"**, "compact", "newline"]

Spacing for keywords following a block.

```cfc
// keywords.block_to_keyword_spacing: "spaced"
if (true) {
} else {
}

// keywords.block_to_keyword_spacing: "compact"
if (true) {
}else {
}

// keywords.block_to_keyword_spacing: "newline"
if (true) {
}
else {
}
```

## keywords.empty_group_spacing

Type: _boolean_

Default: **false**

Whether to pad empty keyword groups.

```cfc
// keywords.empty_group_spacing: true
if ( ) {
}

// keywords.empty_group_spacing: false
if () {
}
```

## keywords.group_to_block_spacing

Type: _string_

Values: [**"spaced"**, "compact", "newline"]

Spacing from a keyword group to the following block.

```cfc
// keywords.group_to_block_spacing: "spaced"
if (true) {
}

// keywords.group_to_block_spacing: "compact"
if (true){
}

// keywords.group_to_block_spacing: "newline"
if (true)
{
}
```

## keywords.padding_inside_group

Type: _boolean_

Default: **false**

Whether to pad inside non-empty keyword groups.

```cfc
// keywords.padding_inside_group: true
if ( true ) {
}

// keywords.padding_inside_group: false
if (true) {
}
```

## keywords.spacing_to_block

Type: _string_

Values: [**"spaced"**, "compact", "newline"]

Spacing from a keyword to the following block.

```cfc
// keywords.spacing_to_block: "spaced"
do {
}

// keywords.spacing_to_block: "compact"
do{
}

// keywords.spacing_to_block: "newline"
do
{
}
```

## keywords.spacing_to_group

Type: _boolean_

Default: **true**

Whether to space a keyword from following group.

```cfc
// keywords.spacing_to_group: true
if (true) {
}

// keywords.spacing_to_group: false
if(true) {
}
```

## max_columns

Type: _integer_

Default: **120**

When rendering a delimited item (struct, array, function call, function declaration parameters), this is the maximum number of columns to render on one line before splitting the elements onto multiple lines.


## metadata.multiline.element_count

Type: _integer_

Default: **4**

When a component or function declaration has this number of metadata attributes or more, print it onto multiple lines.


## metadata.multiline.min_length

Type: _integer_

Default: **40**

No matter how many metadata attributes a component or function declaration has, if it is shorter than this length, keep it on one line.


## method_call.chain.multiline

Type: _integer_

Default: **3**

When a method call chain has this many method calls, always split them onto multiple lines.


## newline

Type: _string_

Values: [**"os"**, "\n", "\r\n"]

The new line character(s) to use. The default is "os" which uses \r\n on Windows, and \n otherwise.


## parentheses.padding

Type: _boolean_

Default: **false**

Whether to pad the contents of a group.

```cfc
// parentheses.padding: true
a = ( 1 + 2 );

// parentheses.padding: false
a = (1 + 2);
```

## property.multiline.element_count

Type: _integer_

Default: **4**

When a property has this number of attributes or more, print it onto multiple lines.


## property.multiline.min_length

Type: _integer_

Default: **40**

No matter how many attributes a property has, if it is shorter than this length, keep it on one line.


## strings.attributes.quote

Type: _string_

Values: ["single", **"double"**, "ignored"]

Whether to use a single or double quote for attribute values. If set to "ignored", leaves attribute value quotes as they are found.

```cfc
// strings.attributes.quote: "single"
http url='www.google.com';
param name='key';

// strings.attributes.quote: "double"
http url="www.google.com";
param name="key";

// strings.attributes.quote: "ignored"
http url='www.google.com';
param name="key";
```

## strings.quote

Type: _string_

Values: [**"single"**, "double", "ignored"]

Whether to use a single or double quote for strings. If set to "ignored", leaves string quotes as they are found.

```cfc
// strings.quote: "single"
a = 'One';
b = 'Two';

// strings.quote: "double"
a = "One";
b = "Two";

// strings.quote: "ignored"
a = "One";
b = 'Two';
```

## strings.convertNestedQuotes

Type: _boolean_

Default: **true**

Whether to convert the quote character for strings that contain quotes within them.

```cfc
// strings.convertNestedQuotes: true
a = '''';

// strings.convertNestedQuotes: false
a = "'";
```

## struct.empty_padding

Type: _boolean_

Default: **false**

When true, non-empty structs are padded with spaces.

```cfc
// struct.empty_padding: true
myStruct = { };

// struct.empty_padding: false
myStruct = {};
```

## struct.multiline.element_count

Type: _integer_

Default: **4**

When a struct has this number of elements or more, print it onto multiple lines.


## struct.multiline.leading_comma

Type: _boolean_

Default: **false**

Whether to use a leading comma when an struct is printed on multiple lines.

```cfc
// struct.multiline.leading_comma: true
myStruct = {
      a: 1
    , b: 2
    , c: 3
    , d: 4
};

// struct.multiline.leading_comma: false
myStruct = {
    a: 1,
    b: 2,
    c: 3,
    d: 4
};
```

## struct.multiline.leading_comma.padding

Type: _boolean_

Default: **true**

Whether to insert a space after leading commas when an struct is printed on multiple lines.

```cfc
// struct.multiline.leading_comma.padding: true
myStruct = {
      a: 1
    , b: 2
    , c: 3
    , d: 4
};

// struct.multiline.leading_comma.padding: false
myStruct = {
     a: 1
    ,b: 2
    ,c: 3
    ,d: 4
};
```

## struct.multiline.min_length

Type: _integer_

Default: **40**

No matter how many elements an struct has, if it is shorter than this length, keep it on one line.


## struct.padding

Type: _boolean_

Default: **false**

Whether to pad non-empty structs with spaces.

```cfc
// struct.padding: true
myStruct = { a: 1, b: 2 };

// struct.padding: false
myStruct = {a: 1, b: 2};
```

## struct.quote_keys

Type: _boolean_

Default: **false**

When true, struct keys are quoted.

```cfc
// struct.quote_keys: true
myStruct = {'a': 1, 'b': 2};

// struct.quote_keys: false
myStruct = {a: 1, 'b': 2};
```

## struct.separator

Default: **": "**

The key value separator to use in structs - it must contain either a single `:` or `=` and be no more than 3 characters in length.

```cfc
// struct.separator: ": "
myStruct = {a: 1, b: 2};

// struct.separator: " = "
myStruct = {a = 1, b = 2};

// struct.separator: " : "
myStruct = {a : 1, b : 2};

// struct.separator: "="
myStruct = {a=1, b=2};
```

## tab_indent

Type: _boolean_

Default: **false**

Whether to indent using tab characters or not.
