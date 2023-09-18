<?php
/*
 * Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// check if control flow constructs do not
// block the collecting of constraints

// if else elseif
if ($a1) {"10";}
if ($b1) {"20";} else {"30";}
if ($c1) {"40";} else if ("50") {$d1;} else {$e1;}
if ($c1) {"40";} elseif ("50") {$d1;} else {$e1;}
// if else elseif without brackets
if ($a2) "11";
if ($b2) "21"; else "31";
if ($c2) "41"; else if ("51") $d2; else $e2;
if ($a1): "12"; endif;

// while
while($f1) { "60"; }
while($f2)  "61";
while ($f3): "62"; endwhile;

// do while
do { $g1; } while ($h1);
do $g2; while ($h2);

// for
for ($i1; $i2; $i3) { "70"; }
for ($i4; ;$i5) { "71"; }
for (; ; ) { "72"; }
for ($i6, $j7; $i8; $j9, $i11, $i12);

// foreach
foreach ($k as $v) foreach ($kk as $vv) "80";
foreach ($arr as $key => $value) { continue $a; "statement"; }
foreach ($array as $element): "81"; endforeach;

// break and continue are ignored!

// switch
switch ($l2) { case 10; case "1str": "string"; break; default: "def"; }
switch ($l2): case 20: "zero2"; break; case "2str": "string"; break; default: "def"; endswitch;

// declare
declare(ticks=1) { $m; }

// goto
goto a; 'Foo';  a: 'Bar';

// try catch
try { $n1; } catch (\Exception $e) { $n2; };
try { $n3; } catch (\Exception $e) { $n4; } finally { $n5; };
