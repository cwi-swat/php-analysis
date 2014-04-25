<?php
# source: http://nl1.php.net/interface

namespace Alpha;

const x = 4;

interface a
{
    const b = 'Interface constant';
}

namespace Beta;
use \Alpha\a;

// Prints: Interface constant
echo a/b;


// This will however not work because it's not allowed to
// override constants.
class b implements a
{
    //const b = 'Class constant'; # not allowed!
}
