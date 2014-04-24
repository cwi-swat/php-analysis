* namespaces
    * `|php+namespace:///A::B|` for namespace `A\B`
    * `|php+namespace:///|` for global namespace
* classes
    * `|php+class:///A::B::C|` for class `C` in namespace `A\B`
    * `|php+class:////C|` for class `C` in global namespace
* interfaces
    * `|php+interface:///A::B/I|` for interface `I` in namespace `A\B`
    * `|php+interface:///I|` for interface `I` in global namespace
* traits
    * `|php+trait:///A::B/T|` for trait `T` in namespace `A\B`
    * `|php+trait:///T|` for trait `T` in global namespace
* methods
    * `|php+method:///A::B/C/m|` for method `m` in class `A\B\C`
    * `|php+method:///C/m|` for method `m` in class `C`
* fields
    * `|php+field:///A::B/C/f|` for field `f` in class `A\B\C`
    * `|php+field:///C/f|` for field `f` in class `C` 
* constants
    * `|php+constant:///A::B/C/c|` for class constant `c` in class `A\B\C`
    * `|php+constant:///C/c|` for class constant `c` in class `C`
* functions
    * `|php+function:///A::B/func|` for class constant `c` in class `A\B\C`
    * `|php+function:///func|` for class constant `c` in class `C`
* parameters
    * for functions
        * `|php+parameter:///A::B/f/p|` for parameter `p` of function `A\B\f`
        * `|php+parameter:///f/p|` for parameter `p` of function `f`
    * for methods
        * `|php+parameter:///A::B/C/m/p|` for parameter `p` of method `m` in class `A\B\C`
        * `|php+parameter:///C/m/p|` for parameter `p` of method `m` in class `C`
* variables
    * global variables
        * `|php+variable:///A::B/v|` for variable `v` in namespace `A\B`
        * `|php+variable:///v|` for variable `v` in global namespace
    * for functions
        * `|php+variable:///A::B/f/v|` for variable `v` in function `A\B\f`
        * `|php+variable:///f/v|` for variable `v` in function `f`
    * for methods
        * `|php+variable:///A::B/C/m/v|` for variable `v` of method `m` in class `A\B\C`
        * `|php+variable:///C/m/v|` for variable `v` of method `m` in class `C`
