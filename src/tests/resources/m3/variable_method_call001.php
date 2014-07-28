<?php 

class X
{
    public $prop = "A";
    
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

$x = $a->prop;
$x = $a->propNonExist;
$a->a = $b;

$ts = "toString";
$a->getClass()->$ts();