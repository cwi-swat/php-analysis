<?php

try {
    $a = new \StdClass();
} catch (\Exception $e) {
    $b = 1;
}

function c() {
    try {
        $d = new \StdClass();
    } catch (\Exception $e) {
        $e = 1;
    }
}

class f {
    function g() {
        try {
            $h = new \StdClass();
        } catch (\LogicException $e) {
            $i = 1;
        } catch (\Exception $e) {
            $j = 1;
        } finally {
            $k = 1;
        }
    }
}
