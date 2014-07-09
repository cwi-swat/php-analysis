<?php
namespace Alpha;

const b = 2;

interface a
{
    const b = 'Interface constant';
}

namespace Beta;
use \Alpha as a;
use \Alpha\a as interfaceA;

// Prints: Interface constant
echo a\b;
echo interfaceA::b;


// This will however not work because it's not allowed to
// override constants.
class b implements interfaceA
{
    //const b = 'Class constant'; # not allowed!
}