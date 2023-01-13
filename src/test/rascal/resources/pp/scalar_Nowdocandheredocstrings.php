<?php

// empty strings
<<<'EOS'
EOS;
<<<EOS
EOS;

// constant encapsed strings
<<<'EOS'
Test '" $a \n
EOS;
<<<EOS
Test '" \$a \n
EOS;

// encapsed strings
<<<EOS
Test $a
EOS;
<<<EOS
Test $a and $b->c test
EOS;

// comment to force line break before EOF
