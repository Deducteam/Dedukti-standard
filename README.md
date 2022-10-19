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

## Module identifiers

Module identifiers are used to represent module names.
A module identifier `<mid>` is recognized by the regular expression `[a-zA-Z0-9_]+`.

**Example:**
  `0baz` is a valid module identifier, but
  `0baz?` is not a valid module identifier.
  However, `0baz?` is a valid identifier.

**Remark**: All module identifier are identifiers.

## Qualified identifiers

The Dedukti standard recognizes qualified identifiers which represent
an identifier in a module. A qualified identifier `<qid>` is:

```
<qid> ::= <mid> "." <id>
```

There cannot be any space between the tokens that make up `<qid>`.

**Example:**
  `A.b` is a valid qualified identifier while
  `A. b` is not.

## Expressions

We describe below the expressions recognized by the standard.

### Terms

```
<sterm> ::= <qid> | <id> | "(" <term> ")" | "Type"

<aterm> ::= <sterm>+

<term> ::= <aterm> 
         | <id> ":" <aterm> "->" <term>
         | (<binding> | <aterm>) "->" <term>
         | <id> (":" <aterm>)? "=>" <term>

<binding> ::= "(" <id ":" <term> ")"
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

### Rewrite rules

```
<pattern> ::= <term>

<context> ::= <id> ("," <id>)*

<rule> ::= "[" <context>? "]" <pattern> "-->" <term>
```

In practice, not every term can be used as a pattern.
The distinction will be made semantically.


## Theories

```
<visibility>   ::= "private"
<definibility> ::=  <visibility>? "injective" | "def"
<type>         ::= ":"  <term>
<definition>   ::= ":=" <term>
<command>      ::= <rule>+
                 | "def" <id> <binding>* <type> <definition>
                 | "thm" <id> <binding>* <type> <definition>
                 | <definibility>? <id> <type>
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
equivalence-preserving preprocessing steps on the theory.
The steps should be executed in the order
in which they are introduced in this section.

## Modules

Each Dedukti theory file defines a *module*.
Any implementation of the standard must provide a way to
associate to each module name `m` a unique filename `m.dk`.
A symbol `x` that was introduced in a module `m` can be referenced

* inside  of module `m` by `m.x` or `x`, and
* outside of module `m` by `m.x`,
  provided that the command `require m` was encountered before.

We globally keep a set `private` of qualified identifiers that is initially empty.

We can *demodulate* a module `m` as follows:
For every command `c` in the file `m.dk`,
if `c` is of the shape `require n`, then demodulate `n`, otherwise:

1. Prefix all non-qualified constants in `c` with `m`.
2. Verify that for any constant `n.x` in `c` such that `n` $\neq$ `m`,
   `private` does not contain `n.x`.
3. If `c` starts with the keyword `private` and declares `m.x`,
   add `m.x` to the set `private` and remove the keyword `private` from `c`.
4. Output `c`.

To check a theory `m`, we check the demodulation of `m`.

**Example:**
  Suppose we have two theory files `basic.dk` and `nat.dk`, where
  `basic.dk` contains `prop : Type.` and
  `nat.dk` contains `nat : Type. 0 : nat. require prop. is_nat : nat -> prop.`.
  Then the demodulation of the module `nat` is the following:
  `basic.prop : Type. nat.nat : Type. nat.0 : nat.nat. nat.is_nat : nat.nat -> basic.prop`.

When a theory `a` requires `b` and `b` requires `a`, then we have a loop.
When a theory `a` requires `b` and `c`, and both `b` and `c` require `d`,
then we have a duplicate requirement.
The demodulation procedure shown above
does not detect loops and
inserts duplicate requirements multiple times.
In order to prevent both, we can augment the demodulation procedure as follows:
We introduce two global sets that are initially empty:
`open` contains the names of modules that are currently being demodulated, and
`closed` contains the names of modules that have been completely demodulated.
At the start of the demodulation of `m`,
we fail if `m` is in `open` (to prevent loops), and
we return if `m` is in `closed` (to prevent inserting `m` twice).
Then we add `m` to `open`.
At the end of the demodulation of `m`,
we move `m` from `open` to `closed`.

## Bindings

We eliminate bindings for commands starting with `def` and `thm`:
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

We now define the set of lambda-Pi terms that we will translate from our syntax to:

A term $t$ is defined as $$t \coloneqq x \mid t\; t \mid \lambda x : t.\; t \mid \Pi x : t.\; t \mid (t) \mid s.$$
A sort $s$ is defined as $\Type \mid \Kind$.

We translate a term `t` as defined in the syntax section to
a term $t$ as defined in this section by $\|$`t`$\|$ as given below.
Here,
`x` / $x$ stand for identifiers, and
`u` / $u$ and `v` / $v$ stand for terms.
Additionally, in the "product" case,
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


## Checking

The [preprocessing steps](#preprocessing) yield a sequence of simplified commands.
We now describe how to check them.

First, we initialise a global context $\Gamma = \emptyset$.
A global context $\Gamma$ contains statements of the shape
$x : A$,
$l \hookrightarrow _\Delta r$,
$x\; \mathrm{injective}$, and
$x\; \mathrm{definable}$.

Next, we perform the following for every command `c`:

* If `c` introduces a set of rewrite rules
  `[ctx1] l1 --> r1 ... [ctxn] ln --> rn`:
  We translate every rewrite rule to
  $l \hookrightarrow _\Delta r$, and verify that
  $\Gamma, \Delta \vdash ^r l \hookrightarrow r\; \mathrm{wf}$ and
  $\Gamma \vdash h\;\mathrm{definable}$, where
  $h$ is the head symbol of $l$.
  At the end, we add all the translated rewrite rules to $\Gamma$.
* If $c$ introduces a new symbol by
  `x : A`,
  we translate $A = \|$`A`$\|$,
  we verify that $\Gamma \vdash A : s$ and $x$ is not in $\Gamma$,
  and we add $x : A$ to $\Gamma$.
* If `c` introduces a new definable symbol by
  `def x : A`, then we perform the same as for `x : A`
  before adding $x\; \mathrm{definable}$ to $\Gamma$.
* If `c` introduces a new injective symbol by
  `injective x : A`, then we perform the same as for `x : A`
  before adding $x\; \mathrm{injective}$ to $\Gamma$.
  It is up to the implementation to verify that
  for all $\vec t$ and $\vec u$ of same length,
  $x \vec t \equiv _{\Gamma\beta} x \vec u$ implies
  $\vec t \equiv _{\Gamma\beta} \vec u$.
* If `c` is an assertion of shape `assert t : A`,
  we verify that $\Gamma \vdash \|$`t`$\| : \|$`A`$\|$.
* If `c` is an assertion of shape `assert t == A`,
  we verify that $\|$`t`$\| \equiv _{\Gamma\beta} \|$`A`$\|$.
* If `c` is a pragma, the behaviour is up to the implementation.
