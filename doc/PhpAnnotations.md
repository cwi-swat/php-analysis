Syntax of `@param`

```
@param <type> <variable_name> [<description>]

// Examples:
@param int $var
@param int|string $input Input of this method is either an integer or a string
@param mixed $in
@param \ClassObject $classObj
@param \Namespace\ClassObject $classObj
```

Syntax of `@return`

```
@return <type> [<description>]

// Examples:
@return void
@return string|int
@return ClassObject|null
@return \Namespace\ClassObject|null
```

Syntax of `@var`

```
@var <type> [variable_name] [<description>]

// Examples:
@var int $var
@var int|string $input Input of this method is either an integer or a string
@var mixed $in
@var \ClassObject $classObj
@var \Namespace\ClassObject $classObj
```