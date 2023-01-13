<?php 

abstract class F {
    private static function A() {}
    public static function B() {}
    static function C() {}
}
class E extends F {
    static function C() {}
}
class D extends E {
    public function __construct()
    {
        echo self::class;
        echo parent::class;
        echo static::class;
    }
}
class C extends D {}
class B extends C {}
class A extends B {}

$o = "A";
$f = "B";
A::a(); // method does not exist
A::A(); // method does not exist
A::b();
A::c();
A::$f();
$o::$f();

$a = new A;
$a::a(); // method does not exist
$a::A(); // method does not exist
$a::b();
$a::c();

$a::$f();