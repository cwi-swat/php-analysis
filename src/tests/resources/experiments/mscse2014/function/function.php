<?php

function a() {}
function &b() {}
function c() { return; }
function d() { return true; return false; }
function f() { function g() { return "string"; } }