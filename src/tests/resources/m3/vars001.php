<?php

$i = 0;          /* global $i */

function f() {
    $i = 3;      /* local $i */
    echo $i;     /* usa of local $i */
}

$i++;            /* use of global $i */
echo $i;         /* use of gloabl $i */