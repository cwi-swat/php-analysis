<?php

function a() {}
function &b() {}
function c() { return; }
function d() { return true; return false; }
function f() { function g() { return "string"; } }
function h() { $a = "str"; $a = 100; }
function i() { $i = "str"; function j() { $i = 100; } }
