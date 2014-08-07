##### Possible Type Constraints:

Declarations:

There are differnt 'levels' of constraints.

* On global level (what classes and functions do exist, what variables)
* ?? not sure: on namespace level...
* On class level (what fields and methods are there, what extends/implements)
* On function/method level (what variables are used within the scope)
* Between scopes (for method calls)

** Types: **

* a variable `$a` has { t1, ..., tn } types. (within a certain scope)
* assignement of variables: `$x = $y` (types of y = types of x)
* return (method|function) can have {} of types: typeof `x->a();` is the return value of `public function a()`
* \> this means that methods 
* call constructor when initializing a method
* result of expression (e.g. `$x + $y`) has a set of possible types.

* handle magic methods: 
  * instantiation -> __construct (return type = null);
  * method call -> __call

#### Declarations

** Variable **
 
 * The type of a variable is the type of the disjunction of all occurances of the variable within a within the scope.
 * On scopes:
   * global scope
   * function scope
   * method scope
   * exception for global key word, it is in the global scope AND in the function/method scope

** Constants **
 
 * Constant

** Interface **

 * Decl: name of the interface
 * Decl: extends (= subtype of ...)

** Trait **

?? out of scope ?? (not used alot, yet... can be added later)

** Class **

 * Decl: name of the class (including namespace)
 * Decl: extends (= subtype of ...)
 * Decl: implement	
 * Decl: has constructor
 * Decl: constructor minimum re	quired fields
  
** Class Constant **

 * Decl: name of the constant
 * Decl: class of the constant
 * Decl: type of the constant (?)
 
** Class Property **

 * Decl: name of the property
 * Decl: class of the property

** Class Methods (/function) **

 * Decl: name of the method
 * Decl: has parameter constraints (see below)
 * Decl: which class the method is in 
 * The return type is the disjunction of the types of all return statements (or void/null when none provided)
 
** Function **

 * Decl: name of the function (including namespace)
 * Decl: has parameter constraints (see below)
 * The return type is the disjunction of the types of all return statements (or void/null when none provided)

** Actual Parameter constraints **
 
 * Decl: Minimum required params
 * Decl: type hints
 
 
#### Types

** Cast operators **

 Casts     | Input                            | Output      | Rascal                | Notes
--- | --- | --- | --- | ---
(array)   | anything                         | array       | `cast(array(), Expr e)`
(bool\|boolean) | anything                         | boolean     | `cast(\bool(), Expr e)`
(int\|integer)     | anything      | int         | `cast(\int(), Expr e)`
(float\|double\|real)   | anything        | double     | `cast(float(), Expr e)`
(string)  | anything besides an object\ | string      | `cast(string(), Expr e)`
(string)  | Object | string or fatal error      | `cast(string(), Expr e)` | * only works if the object has __toString and returning a string 
(object)  | anything                         | object      | `cast(object(), Expr e)`
(unset)   | anything                         | NULL      | `cast(unset(), Expr e)`

## Operators

### Arithmetic Operators:

* please note that the priority is top to bottom (this can be implemented using rascal pattern matching).
* '_' matches any type
* Division and Modulus can trigger 'division by zero' warnings... 

---

** Rules for Negation operator: ** `-l` -> (double | int)

`l` | result
--- | ---
array | error
double | double
_ | integer

---

** Rules for Addition operator: ** `l + r` -> (array | double | int)

`l` | `r` | result
--- | --- | ---
array | array | array
array | _ | fatal error
_ | array | fatal error
double | _ | double
_ | double | double
_ | _ | integer

---

** Rules for Subtraction operator: ** `l - r` -> (array | double | int)

** Rules for Multiplication operator: ** `l * r` -> (array | double | int)

** Rules for Division operator: ** `l / r` -> (array | double | int)

`l` | `r` | result
--- | --- | ---
_ | array | fatal error
array | _ | fatal error
double | _ | double
_ | double | double
_ | _ | integer

---

** Rules for Modulus operator: ** `l % r` -> (int)

`l` | `r` | result
--- | --- | ---
_ | _ | integer

---

### Assignment Operators:

Code | typeOf(`$b`) | typeOf(`$a`) | Notes
--- | --- | --- | ---
`$a &= $b;`  | _ | integer |
`$a \|= $b;`  | _ | integer |
`$a ^= $b;`  | _ | integer |
`$a <<= $b;`  | _ | integer |
`$a >>= $b;`  | _ | integer |
`$a %= $b;`  | _ | integer |
`$a .= $b;` | object* | error | *when object has no __toString() method 
`$a .= $b;` | _ | string | 
`$a /= $b;` | array | error |
`$a /= $b;` | _ | integer |
`$a -= $b;` | array | error |
`$a -= $b;` | _ | integer |
`$a *= $b;` | bool\|int\|null | integer |
`$a *= $b;` | _ | double |
`$a += $b;` | bool\|int\|null | integer |
`$a += $b;` | _ | double |

---

### Bitwise Operators:

** Rules for Bitwise And operator: ** `$a & $b`

** Rules for Bitwise Or (inclusive or) operator: ** `$a | $b`

** Rules for Bitwise Or (exclusive or) operator: ** `$a ^ $b`

typeOf(`$a`) | typeOf(`$b`) | Result | Notes
--- | --- | --- | ---
string | string | string
_ | _ | integer

---

** Rules for Bitwise Shift left operator: ** `$a << $b`

** Rules for Bitwise Shift right operator: ** `$a >> $b`


typeOf(`$a`) | typeOf(`$b`) | Result | Notes
--- | --- | --- | ---
_ | _ | integer | always an integer

---

** Rules for Bitwise Not operator: ** `~$a`

typeOf(`$a`) | Result | Notes
--- | --- | --- | ---
integer\|double | integer
string | string
_ | error

---

### Comparison Operators:

** Rules for Equal operator: ** `$a == $b`

** Rules for Identical operator: ** `$a === $b`

** Rules for Not equal operator: ** `$a != $b`

** Rules for Not equal operator: ** `$a <> $b`

** Rules for Not identical operator: ** `$a !== $b`

** Rules for Less then operator: ** `$a < $b`

** Rules for Greater then operator: ** `$a > $b`

** Rules for Less or equal operator: ** `$a <= $b`

** Rules for Greater or equal operator: ** `$a >= $b`

typeOf(`$a`) | typeOf(`$b`) | Result | Notes
--- | --- | --- | ---
_ | _ | boolean | always a boolean

---

### Incrementing/Decrementing operators

** Rules for Pre-increment operator: ** `++$a`

** Rules for Post-increment operator: ** `$a++`

typeOf(`$a`) | Result | Notes
--- | --- |---
string | {string\|integer\|double}
null | integer
_ | _ | other types do not change type

---
** Rules for Pre-decrement operator: ** `--$a`

** Rules for Post-decrement operator: ** `$a--`

typeOf(`$a`) | Result | Notes
--- | --- | ---
string | {string\|integer\|double}
_ | _ | other types do not change type

---

### Logical Operators:

** Rules for And operator: ** `$a and $b`

** Rules for Or operator: ** `$a or $b`

** Rules for Xor equal operator: ** `$a xor $b`

** Rules for Not equal operator: ** `!$a`

** Rules for And identical operator: ** `$a && $b`

** Rules for Or then operator: ** `$a || $b`

typeOf(`$a`) | typeOf(`$b`) | Result | Notes
--- | --- | --- | ---
_ | _ | boolean | always a boolean

---

** assignments **

```
$b = $a // (sub)typeOf($b) is (sub)typeOf($a)
$c = $b = $a; // (sub)typeOf($a) = (sub)typeOf($b) && (sub)typeOf($b) = (sub)typeOf($c) 

```

** class instantiation **

```
$a = new A; // type of $a is class with name "A"; (FQN: Full Qualified Name)
			// minimum required params = 0;
$a = new A(1);	// type of $a is class with name "A"; (FQN: Full Qualified Name)
				// minimum required params = 0 OR 1;
```

** Ternary operator (elvis) **

```
$a ? $b : $c // result of this whole expression is: typeOf($b) OR typeOf($c)
```

#### Other thoughts...

** Assumption **

I assume that the program is correct. But because it is hard to check if programs are fine in dynamic languagues this is a thread to validity.
 
** Other **

?? Adding scope constraints??

```
hasClassConstant(classDecl, constDecl)
classCont(constDecl, value)
Examples:

	hasClassConstant("A", "C");
		> class A { const C = 1; }
	
	hasField("A", "F");
		> class A { public $F; }

	hasMethod("A", "M");
		> class A { public function M () {} }
	
Subtypes:

	isSubType("A", "B")
		> class A extends B {}	

```
** Note: ** add default classes, functions, variables and constants to the list of declarations


Symbols:

```
a <: b   		| b is a subtype of a; 
				| example: class b extends a {}
```

```
$a = $b; 		| subtype of a is the subtype of b
				| syntax: varType($a) <: varType($b);

$a->call()		| typeOf(a) has method "call" OR magic method __call

$a->call($b)	| typeOf(a) has method "call" OR magic method __call
				| typeOf(b) is a subtype of formal parameter 1
				
// minimum number of params 

```

** Constraint Examples **

```
syntax below: 

php code		# constraint that can be derifed


class A {}		# Type A is defined here.

$a = new A{};	# $a is of type A;
$b = $a;		# $b is the same type as $a; ==> eq(typeOf(a),typeOf(b))
$b->do();		# type (or supertype) of $b has method "do"

$c = $b->do(new O)	# type (or supertype) of b has method "do"
					# type of param1 (new O) is a subtype of formal param1
					# return of b->do is of type c
$foo->call()->bar->chain();
	# type of $foo has method "all"
	# return type of $foo->call has field bar
	# type of field bar has method "chain"
```


How to solve constraints:
	Keep resolving till you have non left.
	
	
Advantages: (what can we use it for?)

* IDE support!!
* Perform better (static) code analysis
* Find source code l



