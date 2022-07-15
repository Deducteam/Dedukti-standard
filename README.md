# Dedukti language -- draft

## Syntax

### Comments

Comments are multi line, opened by `(;` and closed by `;)`. There
may be nested comments, `(; foo (; bar ;) baz ;)` is correct.

### Characters

The standard characters for the language are defined by [Unicode
standard annex
31](https://www.unicode.org/reports/tr31/tr31-33.html)[^1].

We define the classes of identifiers and qualified identifiers,

```
id ::= _annex 31_
     | "{|" _anything but pipe brace_ "|}"
mid ::= id
qid ::= id "." id
```

Escaped identifiers `{|foo space|}` ought to accept anything as identifier but
the string `|}`. Semantically, `{|foo|}` is the same as `foo`, but `{|fo o|}`
is no the same as `fo o`.

### Terms

#### Option 1: legacy terms

Legacy Dedukti, no primitive "let-in" construction. Non dependent
products allowed. Type annotations for abstractions mandatory.

```
t ::= "TYPE" | qid | t t
    | "(" id ":" t ")" "->" t
    | t "->" t
    | "(" id ":" t ")" "=>" t
    | "(" t ")"
```

#### Option 2: Twelf-style terms

```
t ::= "TYPE" | qid | t t
    | "{" id ":" t "}" t
    | t "->" t
    | "[" id ":" t "]" t
    | "(" t ")"
```

Where abstractions are written "`[x : A] e`" and dependent products
"`{x: A} B`".

### Rewrite rules

Legacy Dedukti syntax.

```
rules ::= ("[" id* "]" t "-->" t)* "."
```

### Symbol declarations

```
visibility ::= "private" | "protected"
statement ::= visibility? "constant" id ":" t "."
            | visibility? "injective"? "symbol" id ":" t "."
	    | visibility? "definition" id (":" t)? ":=" t "."
```

Opacity is left as a pragma.

### Module declaration

```
fname ::= _unix filename_
mod-decl ::= "module" mid ("with" mid+)? "."
```

Semantically, `module Foo with Bar Baz.` creates a module `Foo` using modules
`Bar` and `Baz`. The location of the source files where `Bar` and `Baz` are
found is left unspecified. A qualified identifier `Frobz.x` is valid only if
`Frobz` is listed in the imported modules.

There can be several modules per files. A module cannot refer to a
module defined later in the file[^2].

Assertions
----------

Three primitive judgements

```
assertion ::= "assert" (id ":" t)* "|-" t "."
            | "assert" (id ":" t)* "|-" t ":" t "."
	    | "assert" (id ":" t)* "|-" t "==" t "."
```

that encode typability (inference), type checking and convertibility.

Pragma
------

Compiler specific instructions. Pragmas are comments with a particular syntax.

```
pragma ::= "(;#" stuff "#;)"
```

[^1]: also used by Rust

[^2]: easier to compile
