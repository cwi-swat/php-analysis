<?php 

$a = "b";
$$a = "bee";
echo $b;
echo $$a;

class C {
    function f() {
        $a = "b";
        $$a = "bee";
        echo $b;
        echo $$a;
    }
}

function f() {
    $a = "b";
    $$a = "bee";
    echo $b;
    echo $$a;
}