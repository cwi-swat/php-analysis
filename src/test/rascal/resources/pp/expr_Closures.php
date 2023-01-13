<?php
function ($a)
{
    $a;
}

;
function ($a) use ($b)
{
}

;
function () use ($a, &$b)
{
}

;
function &($a)
{
}

;
static function ()
{
};
