<?php

function f() {
    if ($a = 4)
        return $f = 1;
}

if (!function_exists("f")) {
    function f() {
        if ($b = 4)
            return $c = 1;
    }
    function g() { return $g = 2; }
}

function h() {
    $h = true ? 1 : 2;
    return;
}

class C {
    const thisClassIsUsed = true;
}

if (!class_exists("C")) {
    class C {
        const thisClassIsUsed = false;
        const constIsNeverUsed = true;
    }
    class D {
        const thisClassIsUsed = false;
        const constIsNeverUsed = true;
    }
} else if (false) {
    $elseIf = false;
} else {
    $else = true;
}
