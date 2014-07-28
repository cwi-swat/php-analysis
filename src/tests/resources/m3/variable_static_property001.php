<?php 

class A 
{
    public $a = "a";
}

$prop = "a";
$a = new A;
$a->a;
$a->$prop;