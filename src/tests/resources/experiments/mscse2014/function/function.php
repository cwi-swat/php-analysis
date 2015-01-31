<?php

function a() {}
function &b() {}
function c() { return; }
function d() { return true; return false; }
function f() { function g() { return "string"; } }
function h() { $a = "str"; $a = 100; }
function i() { $i = "str"; function j() { $i = 100; } }
if (true) { function k() { $k1; } } else { function k() { $k2; } }
a();
b();
x(); // does not exists
$x(); // variable call
