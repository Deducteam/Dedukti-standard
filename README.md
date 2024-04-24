# Dedukti standard

This document aims to specify the version 1.0 of the Dedukti standard.
This standard aims to document a language based upon the
Lambda-Pi Calculus Modulo Theory.

# Syntax

Any file that represents Dedukti standard character can be encoded
using UTF-8. Any UTF-8 character will be written using the syntax
`U+xxxx`. For example, `U+0061` represents the character `A`.

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

### Pragmas

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

- simple identifiers `<sid>` are recognized by the regular expression
  `[a-zA-Z0-9_!?][a-zA-Z0-9_!?']*` but cannot be a `<keyword>`.

- wrapped identifiers `<wid>` are recognized by the regular expression
  `{|<chr>*|}` such that `<chr>*` is any sequence of UTF-8 characters
  except `|}`.

```
<id> ::= <sid> | <wid>
```

**Example:**
  `0baz` is a valid simple identifier.
  `{|Gödel's theorem|}` is a valid wrapped identifier.
  But `Erdős`, or `def` are not valid identifiers.

**Remark:** The identifiers `a` and `{|a|}` are different.

### Module identifiers

Module identifiers are used to represent module names.
A module identifier `<mid>` is recognized by the regular expression `[a-zA-Z0-9_]+`.

**Example:**
  `0baz` is a valid module identifier, but
  `0baz?` is not a valid module identifier.
  However, `0baz?` is a valid identifier.

**Remark**: All module identifier are identifiers.

### Qualified identifiers

The Dedukti standard recognizes qualified identifiers which represent
an identifier in a module. A qualified identifier `<qid>` is:

```
<qid> ::= <mid> "." <id>
```

There cannot be any space between the tokens that make up `<qid>`.

**Example:**
  `A.b` is a valid qualified identifier while
  `A. b` is not.

## Terms {#dk-terms}

```
<sterm> ::= <qid> | <id> | "(" <term> ")" | "Type"

<aterm> ::= <sterm>+

<term> ::= <aterm> 
         | <id> ":" <aterm> "->" <term>
         | (<binding> | <aterm>) "->" <term>
         | <id> (":" <aterm>)? "=>" <term>

<binding> ::= "(" <id> ":" <term> ")"
```

**Remark:**
  The syntax allows to write lambda abstractions where
  the type of the variable may or may not be given.
  We call a term $t$ *lambda-typed* when
  a type is given for all variables of all lambda abstractions in $t$, and
  we call a term *lambda-untyped* when
  no type is given for all variables of all lambda abstractions in $t$.
  Later on, when checking that a term $t$ is of type $A$,
  the standard covers only the case that $t$ and $A$ are lambda-typed,
  whereas when checking that a rewrite rule $l \hookrightarrow _\Delta r$ is well-typed,
  the standard covers only the case that $l$ is lambda-untyped and $r$ is lambda-typed.

## Rewrite rules

```
<pattern> ::= <term>

<context> ::= <id> ("," <id>)*

<rule> ::= "[" <context>? "]" <pattern> "-->" <term>
```

In practice, not every term can be used as a pattern.
The distinction will be made semantically.


## Theories

```
<sig>          ::= <id> <binding>* ":" <term>
<command>      ::= <rule>+
                 | ("def" | "thm") <sig> ":=" <term>
                 | ("def" | ("private"? "injective"))? <sig>
                 | "require" <mid>
                 | "assert" <term> ":" <term>
                 | "assert" <term> "=" <term>
                 | "#" <pragma>
<theory>       ::= (<command> "." (<space> <command> ".")*)?
```

The initial symbol for the grammar recognized by the Dedukti standard is `<theory>`.
By convention, the suffix of a file using this standard is `.dk`.

Pragma provide commands which are implementation dependent and do not
need to be supported. This way, a file containing a pragma is
syntactically valid for the different tools implementing the
standard. A pragma that is not supported by a tool can simply be
ignored. For example:

```
#CHECK A : Type.
```

could be a pragma used to check whether `A` is a term that has type `Type`.


# Preprocessing

To simplify the semantics, we perform a few
equivalence-preserving preprocessing steps on commands.
The steps should be executed in the order
in which they are introduced in this section.

## Bindings

We eliminate bindings for commands that introduce symbols
(e.g. commands starting with `def`, `thm`, or `injective`):
if a type is given, we add bindings as dependent  products  to the type;
if a term is given, we add bindings as lambda abstractions to the term.

**Example:**
  A command of the shape
  `thm id (v1: ty1) ... (vn: tyn) : ty := tm`
  is replaced by the equivalent
  `thm <id> : v1 : ty1 -> ... -> vn : tyn -> ty := v1 : ty1 => ... => vn : tyn => tm`.

## Definitions / Theorems

We replace commands of the shape
`def id : ty := tm` by the sequence of the two commands
`def id : ty` and
`[] id --> tm`.
Furthermore, we replace commands of the shape
`thm id : ty := tm` by the sequence of the two commands
`id : ty` and
`assert tm : ty`.

## Jokers

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


# Semantics

In this section, we describe how to check a theory.

## Terms

We define the set of lambda-Pi terms that we will translate from our syntax to:

A term $t$ is defined as
$$t \coloneqq
x \mid
t\; t \mid
\lambda x.\; t \mid
\lambda x : t.\; t \mid
\Pi x : t.\; t \mid
(t) \mid
s.$$
A sort $s$ is defined as $\Type \mid \Kind$.

We translate a term `t` as defined in [the syntax section](#dk-terms) to
a term $t$ as defined in this section by $\|$`t`$\|$ as given below.
Here,
`x` / $x$ stand for identifiers, and
`u` / $u$ and `v` / $v$ stand for terms.
Additionally, in the (non-dependent) "product" case,
$x$ must be chosen to be fresh and not to appear freely in $\|$`v`$\|$.

Table: Term translation.

Case               | `t`          | $\|$`t`$\|$
------------------ | ------------ | ---------------------------------
Parentheses        | `(u)`        | $(\|u\|)$
Type               | `Type`       | $\Type$
Identifier         | `x`          | $x$
Application        | `u v`        | $\|$`u`$\| \|$`v`$\|$
Lambda abstraction | `x : u => v` | $\lambda x: \|$`u`$\|. \|$`v`$\|$
Dependent product  | `x : u -> v` | $\Pi     x: \|$`u`$\|. \|$`v`$\|$
Product            |     `u -> v` | $\Pi     x: \|$`u`$\|. \|$`v`$\|$

## Rules

\input{rules.tex}

It can be necessary to introduce sets of rewrite rules where
subsets of the rules are not terminating and confluent,
but the whole set is.
Consider the rewrite rules
$a \hookrightarrow b$,
$a \hookrightarrow c$,
$b \hookrightarrow d$, and
$c \hookrightarrow d$.
The four rules together are terminating and confluent,
but when omitting either the third or the fourth rule,
the set is not confluent.

TODO: Add a new rule that checks termination and confluence for *sets* of rewrite rules, not for individual rules!

## Modules

Each Dedukti theory file defines a *module*.
Any implementation of the standard must provide a way to
associate to each module name `m` a unique filename `m.dk`.
A symbol `x` that was introduced in a module `m` can be referenced

* inside  of module `m` by `m.x` or `x`, and
* outside of module `m` by `m.x`,
  provided that the command `require m` was encountered in the current theory before.


## Checking

First, we initialise a few global variables:

* $\Gamma$:
  A global context $\Gamma$ contains statements of the shape
  $x : A$ and
  $l \hookrightarrow _\Delta r$.
* `open` (set of module names):
  When a theory `a` requires `b` and `b` requires `a`,
  then we should detect an infinite loop.
  For this, we insert `a` into `open` when we start checking it and
  remove it from `open` only once we have finished checking it.
  This allows us to conclude an infinite loop when
  upon checking `a`, `a` is already in `open`.
* `checked` (set of module names):
  When a theory `a` requires `b` and `c`, and both `b` and `c` require `d`,
  then checking `a` should only check `d` once.
  For this, we insert `d` into `checked` once it has been checked,
  in order to prevent `d` to be checked a second time.
* `private`,
  `definable`, and
  `injective` (sets of quantified identifiers).

All these sets are initially empty.

To check a module `m`, we perform the following.

If `m` is in `open`, we fail, otherwise we add `m` to `open`.
If `m` is in `checked`, we are done checking `m`.

We initialise a local variable `required`, which stores
the set of modules from which the current module may access symbols.
This is a local and not a global variable for the following reason:
If we have a module `a` depending on `b` and `b` depending on `c`,
then `a` should not automatically have access to symbols from `c`,
because if `b` stops depending on `c`, `a` should still check successfully.
In other words, `require` is not transitive.

For every command `c` in the module `m`, we first
prefix all non-qualified constants in `c` with `m`, then
verify that for any constant `n.x` in `c`, if `n` $\neq$ `m`, then
`required` must contain `n` and
`private`  must not contain `n.x`.
Then, we [preprocess](#preprocessing) `c`, then perform the following:

* If `c` declares a dependency on a module by `require m`,
  we add `m` to `required` and check `m`.
* If `c` introduces a set of rewrite rules
  `[ctx1] l1 --> r1 ... [ctxn] ln --> rn`:
  We translate every rewrite rule to
  $l \hookrightarrow _\Delta r$, and verify that
  $\Gamma, \Delta \vdash ^r l \hookrightarrow r\; \mathrm{wf}$ and
  $h$ is in `definable`, where
  $h$ is the head symbol of $l$.
  At the end, we add all the translated rewrite rules to $\Gamma$.
* If $c$ introduces a new symbol by
  `x : A`,
  we translate $A = \|$`A`$\|$,
  we verify that $\Gamma \vdash A : s$ and $x$ is not in $\Gamma$,
  and we add $x : A$ to $\Gamma$.
. If `c` introduces a new private symbol by
  `private x : A`, then we perform the same as for `x : A`
  before adding $x$ to `private`.
* If `c` introduces a new definable symbol by
  `def x : A`, then we perform the same as for `x : A`
  before adding $x$ to `definable`.
* If `c` introduces a new injective symbol by
  `injective x : A`, then we perform the same as for `x : A`
  before adding $x$ to `injective`.
  It is up to the implementation to verify that
  for all $\vec t$ and $\vec u$ of same length,
  $x \vec t \equiv _{\Gamma\beta} x \vec u$ implies
  $\vec t \equiv _{\Gamma\beta} \vec u$.
* If `c` is an assertion of shape `assert t : A`,
  we verify that $\Gamma \vdash \|$`t`$\| : \|$`A`$\|$.
* If `c` is an assertion of shape `assert t == A`,
  we verify that $\|$`t`$\| \equiv _{\Gamma\beta} \|$`A`$\|$.
* If `c` is a pragma, the behaviour is up to the implementation.

Finally, we add `m` to `checked` and remove `m` from `open`.
