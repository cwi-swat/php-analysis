<?php

namespace NS;

class C1 { public function m1() {} }
class C2 { public function m2() { function f1() { return "a"; } return true; } }
class C3 { public function m3() { $a = 2; function f1() { $a = "a"; } return $a; } }
