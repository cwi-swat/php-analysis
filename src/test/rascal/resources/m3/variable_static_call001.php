<?php 

class X
{
    public function toString() {
        echo __CLASS__;
    }

    public function getClass() {
        return $this;
    }
}
$x = "X";
$a = new $x;
$a->toString();

$ts = "toString";
$a->getClass()->$ts();