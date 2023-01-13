<?php

class Class_ {
    const A = 'B', C = 'D';

    public $publicFieldB = 'b', $publicFieldC= 'd';
    protected $protectedField;
    private $privateField;

    public function publicFunction() {}
    public static function publicStaticFunction() {}
    public final function publicFinalFunction() {}
    protected function protectedFunction() {}
    private function privateFunction() {}
}
