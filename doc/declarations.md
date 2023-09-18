---
title: Declarations
---

Here we document the qualified naming scheme for the locations  we used.

* namespaces
    * `|php+namespace:///a/b|` for namespace `A\B`
    * `|php+namespace:///|` for global namespace
* classes
    * `|php+class:///a/b/c|` for class `C` in namespace `A\B`
    * `|php+class:////c|` for class `C` in global namespace
* interfaces
    * `|php+interface:///a/b/i|` for interface `I` in namespace `A\B`
    * `|php+interface:///i|` for interface `I` in global namespace
* traits
    * `|php+trait:///a/b/c|` for trait `T` in namespace `A\B`
    * `|php+trait:///t|` for trait `T` in global namespace
* methods
    * `|php+method:///a/b/c/m|` for method `m` in class `A\B\C`
    * `|php+method:///c/m|` for method `m` in class `C`
* fields
    * `|php+field:///a/b/c/f|` for field `f` in class `A\B\C`
    * `|php+field:///c/f|` for field `f` in class `C`
* constants
    * `|php+constant:///a/b/c/c|` for class constant `c` in class `A\B\C`
    * `|php+constant:///c/c|` for class constant `c` in class `C`
* functions
    * `|php+function:///a/b/func|` for function `func` in namespace `A\B`
    * `|php+function:///func|` for function `func` in global namespace
* parameters
    * for functions
        * `|php+functionParam:///a/b/f/p|` for parameter `p` of function `A\B\f`
        * `|php+functionParam:///f/p|` for parameter `p` of function `f`
    * for methods
        * `|php+methodParam:///a/b/c/m/p|` for parameter `p` of method `m` in class `A\B\C`
        * `|php+methodParam:///c/m/p|` for parameter `p` of method `m` in class `C`
* variables
    * global variables
        * `|php+globalVar:///a/b/v|` for variable `v` in namespace `A\B`
        * `|php+globalVar:///v|` for variable `v` in global namespace
    * for functions
        * `|php+functionVar:///a/b/f/v|` for variable `v` in function `A\B\f`
        * `|php+functionVar:///f/v|` for variable `v` in function `f`
    * for methods
        * `|php+methodVar:///a/b/c/m/v|` for variable `v` of method `m` in class `A\B\C`
        * `|php+methodVar:///c/m/v|` for variable `v` of method `m` in class `C`
