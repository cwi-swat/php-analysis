<?php

namespace NS\FunctionInClass {
    $global = 0;

    function f() {
        $private = "f";
    }

    class C {
        function f($p) {
            $private = "f";
            function ff($pp) {
                $private = "ff";
                function fff($ppp) {
                    $private = "fff";
                }
            }
        }
    }
}

namespace NS\ClassInFunction {
    function g ($gg) {
        $ggg = 1;
        class D {
           function d($dd) { $ddd = 1; }
        }
        interface E {

        }
    }
    function h ($hh) {
        $hhh = 1;
        function i ($ii) {
            $iii = 1;
            class E {
                function __construct($ee) { $eee = 1; }
            }
        }
    }
}

namespace {
    use NS\FunctionInClass\C;
    $c = new C();
    $c->f(1);
    //ff(1);
    \NS\FunctionInClass\ff(1);
    g();
}