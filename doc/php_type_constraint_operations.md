---
title: PHP Type Constraint Operations
---

Here we document some examples of the type inference constraints  we extract from PHP code.

## Assign operators (some sort of case)

```
$a .= ... // $a is a String
$a *= ... // $a is an Integer
etc...

$x = (int) $y; // $x = Integer
$x = 1; // $x = Integer
```

## Method call

```
$a -> methodCall();
// the type of $a has methodCall(); || type of $a has __clone() (magic method)

```

## Conditional statements 

```
$a instanceOf "C" // is_a
// type of $a is (a child of) class C || type of $a implements interface C

is_numeric($a) // $a is numeric
is_bool($a) // $a is a boolean
```

## Member addition 

```
class Empty {}
$e = new Empty();
$e->newField = "value"; // newField is added
echo $e->newField; // newField is used
```

## Return types of methods and functions 

```
function f () { return true }; // return type of f is a boolean
```

## Object instantiation 

```
$x = new Obj; // $x = instance of class Obj
```
** Parameters (number of required params and type hints) **

```
function getPersonId(Person $p) {
	return rand(100);
}
getPersonId(new Person()); // correct
getPersonId(new Person(), 1, 2, true); // correct
getPersonId(); // incorrect
```

## self/static/parent **

```
self::methodCall(); // current class
parent::methodCall(); // one of the parent classes
static::methodCall(); // class of instantiation
```

## Out of scope 

```
- Variable variables (resolve to everything)
- Variable method calls (resolve to everything)
- Eval
```


## Other Notes

```
non parsing scripts are ignored
```
