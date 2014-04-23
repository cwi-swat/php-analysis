<?php

switch ($a = 3) {
    case 0:
        $b = 1;
        break;
    default: {
        $c = 1;
    }
}

function c() {
    switch ($a = 3) {
        case 0:
            $b = 1;
            break;
        default: {
            $c = 1;
        }
    }
}

class f {
    function g() {
        switch ($a = 3) {
            case 0:
                $b = 1;
                break;
            default: {
                $c = 1;
                function d () {
                    $e = 1;
                }
            }
        }
    }
}
