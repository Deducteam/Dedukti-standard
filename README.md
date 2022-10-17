# Dedukti standard

This document aims to specify the version 1.0 of the Dedukti
standard. This standard aims to document a language based upon the
Lambda-Pi Calculus Modulo Theory.

Any file that represents Dedukti standard character can be encoded
using UTF-8. Any UTF-8 character will be written using the syntax
`U+xxxx`. For example, `U+0061` represents the character `A`.

# Syntax

## Lexicon 

This section documents the tokens recognized by the language. Two
consecutive tokens can be separated by a arbitrary number of spaces
defined below.

### Comments

The token `<comment>` starts with `(;` and ends with `;)`. In
particular, nested comments are allowed such as:

```
(; foo (; bar ;) baz ;)
```

### Spaces

The token `<space>` is either one of the three following characters
- `U+0020`: a space
- `U+0009`: a tab (`\t`)
- `U+000D`: a carriage return (`\r`)
- `U+000A`: a new line character (`\n`)

or a `<comment>`.

### Pragma

The token `<pragma>` is defined as any sequence of UTF-8 characters
that do not contain the token `<escape>`. The token `<escape>` is
defined as a dot `.` (`U+002E`), followed by `<space>` or `EOF`.

### Keywords

Keywords are sequences of UTF-8 characters that have a particular
meaning for the Dedukti standard. A keyword **cannot** be used in the
various identifiers defined below.

The Dedukti standard defines a superset of keywords that are
actually used. The keywords are defined below:

```
<keyword> ::= Type | def | defac | defacu | thm | private | injective.
```

### Identifiers

Identifiers are used to represent variables and constant names.

Identifiers `<id>` come into two variants:

- simple identifiers `<sid>` are recognized by the regexp
  `[a-zA-Z0-9_!?][a-zA-Z0-9_!?']*` but cannot be a `<keyword>`.

- wrapped identifiers `<wid>` are recognized by the regexp
  `{|<chr>*|}` such that `<chr>*` is any sequence of UTF-8 characters
  except `|}`.

```
<id> ::= <sid> | <wid>
```

**Example:** `0baz` is a valid simple identifier. `{|😀|}` is a valid
  wrapped identifier. But`😢`, or `def` are not valid identifiers.

**Remark:** The identifiers `a` and `{|a|}` are different.

## Module identifiers

Module identifiers are used to represent module names.

- module identifier `<mid>` are recognized by the regexp `[a-zA-Z0-9_]+`

**Example:** `0baz` is a valid module identifier, but `0baz?` is not a
  valid module identifier. However `0baz?` is a valid identifier.

**Remark**: All module identifier are identifiers.

## Qualified identifiers

The Dedukti standard recognized qualified identifiers which represent
an identifier in a module. A qualified identifier `<qid>` is:

```
<qid> ::= <mid> "." <id>
```

There cannot be any space between the tokens that make up `<qid>`.

**Example:** `A.b` is a valid qualified identifier while `A. b` is
  not.

## Expressions

We describe below the expressions recognized by the standard.

### Terms

```
<sterm> ::= <qid> | <id> | "(" <term> ")" | "Type"

<aterm> ::= <sterm>+

<term> ::= <aterm> 
         | <id> ":" <aterm> "->" <term>
	 | (<binding> | <aterm>) "->" <term>
	 | <id> ":" <aterm> "=>" <term>

<binding> ::= "(" <id ":" <term> ")"
```

### Patterns

Patterns are used for rewrite rules.

```
<pattern> ::= <term>
```

In practice, not every term can be used as a pattern. The distinction
will be made semantically.

### Rewrite rule

```
<rule_binding> ::= <id> (":" <term>)?

<rule_bindings> ::= <rule_binding> ("," <rule_binding>)*

<rules> ::= ("[" <rule_bindings>? "]" <pattern> "-->" <term>)+ 
```

## Theory

```
<visibility>     ::= "private"
<definibility>   ::=  <visibility>? "injective" | "def"
<type>           ::= ":"  <term>
<definition>     ::= ":=" <term>
<command>        ::= <rules>
	           | "def" <id> <binding>* <type>  <definition>
	           | "thm" <id> <binding>* <type>? <definition> 
		   | <definibility>? <id> <type> 
		   | "require" <mid>
		   | "assert" <term> ":" <term>
		   | "assert" <term> "=" <term>
		   | "#" <pragma>
<theory>	 ::= (<command> "." (<space> <command> ".")*)?
```

The initial symbol for the grammar recognized by the Dedukti standard
is `<theory>`. By convention, the suffix of a file using this standard
is "dk".

Pragma provide commands which are implementation dependent and do not
need to be supported. This way, a file containing a pragma is
syntactically valid for the different tools implementing the
standard. A pragma that is not supported by a tool can simply be
ignored. For example:

```
#CHECK A : Type.
```

could be a pragma used to check whether `A` is a term that has type
`Type`.


# Semantics

In this section, we describe how to check a theory.


## Preprocessing

To simplify the semantics, we perform a few
equivalence-preserving preprocessing steps on the theory.

### Bindings

We eliminate bindings for commands starting with `def` and `thm`:
if a type is given, we add bindings as dependent  products  to the type;
if a term is given, we add bindings as lambda abstractions to the term.

For example, a command of the shape
`thm id (v1: ty1) ... (vn: tyn) : ty := tm`
is replaced by the equivalent
`thm <id> : v1 : ty1 -> ... -> vn : tyn -> ty := v1 : ty1 => ... => vn : tyn => tm`.

### Definitions

We replace commands of the shape `def id : ty := tm` by
the sequence of the two commands
`def id : ty` and
`[] id --> tm`.

### Jokers

A command of the shape `[ctx] l --> r` introduces a rewrite rule with
a context `ctx`, a left-hand side `l` and a right-hand side `r`.
Any identifier `_` that occurs freely in the left-hand side of a rewrite rule
is called a joker or wildcard.

We eliminate all jokers from a rewrite rule as follows:
While the left-hand side of a rule contains at least one joker, we
replace that joker by a fresh variable and
add the fresh variable to the context.
For example, the rewrite rule
`[x] f x _ _ --> g x` could be transformed to
`[x, y, z] f x y z --> g x`, if `y` and `z` are fresh variables.

We eliminate jokers from all rewrite rules.
