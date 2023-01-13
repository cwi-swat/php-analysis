<?php

use A as B;
use A;
use A\B;
use C\D as E;
use F\G as H;
use J;

// evil alias notation - Do Not Use!

// function and constant aliases
function foo\bar;
function foo\bar as baz;
const foo\BAR;
const foo\BAR as BAZ;
