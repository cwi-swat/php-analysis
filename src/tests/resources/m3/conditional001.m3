m3(|file:///|)[
  @declarations={
    <|php+function:///f|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(7,55,<3,0>,<3,0>)>,
    <|php+functionVar:///f/a|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(30,2,<4,0>,<4,0>)>,
    <|php+functionVar:///f/f|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(53,2,<5,0>,<5,0>)>,
    
    <|php+function:///f|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(97,67,<9,0>,<9,0>)>,
    <|php+functionVar:///f/b|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(124,2,<10,0>,<10,0>)>,
    <|php+functionVar:///f/c|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(151,2,<11,0>,<11,0>)>,
    
    <|php+function:///g|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(169,31,<13,0>,<13,0>)>,
    <|php+functionVar:///g/g|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(191,2,<13,0>,<13,0>)>,
    
    <|php+function:///h|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(204,51,<16,0>,<16,0>)>,
    <|php+functionVar:///h/h|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(223,2,<17,0>,<17,0>)>,
    
    <|php+class:///c|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(257,45,<21,0>,<21,0>)>,
    <|php+classConstant:///c/thisClassIsUsed|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(277,22,<22,0>,<22,0>)>,
    
    <|php+class:///c|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(334,93,<26,0>,<26,0>)>,
    <|php+classConstant:///c/thisClassIsUsed|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(358,23,<27,0>,<27,0>)>,
    <|php+classConstant:///c/constIsNeverUsed|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(397,23,<28,0>,<28,0>)>,
    
    <|php+class:///d|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(432,93,<30,0>,<30,0>)>,
    <|php+classConstant:///d/thisClassIsUsed|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(456,23,<31,0>,<31,0>)>,
    <|php+classConstant:///d/constIsNeverUsed|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(495,23,<32,0>,<32,0>)>,
    
    <|php+globalVar:///elseIf|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(550,7,<35,0>,<35,0>)>,
    <|php+globalVar:///else|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(580,5,<37,0>,<37,0>)>
  },
  @containment={
    <|php+namespace:///|,   |php+function:///f|>,
    <|php+function:///f|,   |php+functionVar:///f/a|>,
    <|php+function:///f|,   |php+functionVar:///f/f|>,

    <|php+function:///f|,   |php+functionVar:///f/b|>,
    <|php+function:///f|,   |php+functionVar:///f/c|>,

    <|php+namespace:///|,   |php+function:///g|>,
    <|php+function:///g|,   |php+functionVar:///g/g|>,

    <|php+namespace:///|,   |php+function:///h|>,
    <|php+function:///h|,   |php+functionVar:///h/h|>,

    <|php+namespace:///|,   |php+class:///c|>,
    <|php+class:///c|,      |php+classConstant:///c/thisClassIsUsed|>,
    <|php+class:///c|,      |php+classConstant:///c/constIsNeverUsed|>,

    <|php+namespace:///|,   |php+class:///d|>,
    <|php+class:///d|,      |php+classConstant:///d/thisClassIsUsed|>,
    <|php+class:///d|,      |php+classConstant:///d/constIsNeverUsed|>,

    <|php+namespace:///|,   |php+globalVar:///elseIf|>,
    <|php+namespace:///|,   |php+globalVar:///else|>
  },
  @modifiers={
	},
  @uses={
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(69,15,<8,0>,<8,0>),|php+function:///function_exists|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(228,4,<17,0>,<17,0>),|php+constant:///true|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(295,4,<22,0>,<22,0>),|php+constant:///true|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(309,12,<25,0>,<25,0>),|php+function:///class_exists|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(376,5,<27,0>,<27,0>),|php+constant:///false|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(416,4,<28,0>,<28,0>),|php+constant:///true|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(474,5,<31,0>,<31,0>),|php+constant:///false|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(514,4,<32,0>,<32,0>),|php+constant:///true|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(537,5,<34,0>,<34,0>),|php+constant:///false|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(560,5,<35,0>,<35,0>),|php+constant:///false|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/conditional001.php|(588,4,<37,0>,<37,0>),|php+constant:///true|>
  }
]