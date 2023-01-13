m3(|file:///|)[
  @declarations={
    <|php+interface:///a|,  |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(45,42,<3,0>,<3,0>)>,
    <|php+method:///a/foo|, |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(63,22,<5,0>,<5,0>)>,
    <|php+interface:///b|,  |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(89,42,<8,0>,<8,0>)>,
    <|php+method:///b/bar|, |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(107,22,<10,0>,<10,0>)>,
    <|php+interface:///c|,  |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(133,55,<13,0>,<13,0>)>,
    <|php+method:///c/baz|, |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(164,22,<15,0>,<15,0>)>,
    <|php+class:///d|,      |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(190,140,<18,0>,<18,0>)>,
    <|php+method:///d/foo|, |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(217,33,<20,0>,<20,0>)>,
    <|php+method:///d/bar|, |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(256,33,<24,0>,<24,0>)>,
    <|php+method:///d/baz|, |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(295,33,<28,0>,<28,0>)>
  },
  @containment={
    <|php+namespace:///|,   |php+interface:///a|>,
    <|php+namespace:///|,   |php+interface:///b|>,
    <|php+namespace:///|,   |php+interface:///c|>,
    <|php+namespace:///|,   |php+class:///d|>,

    <|php+interface:///a|,  |php+method:///a/foo|>,
    <|php+interface:///b|,  |php+method:///b/bar|>,
    <|php+interface:///c|,  |php+method:///c/baz|>,


    <|php+class:///d|,  |php+method:///d/foo|>,
    <|php+class:///d|,  |php+method:///d/bar|>,
    <|php+class:///d|,  |php+method:///d/baz|>
  },
  @uses={
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(153,1,<13,0>,<13,0>),|php+interface:///a|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(156,1,<13,0>,<13,0>),|php+interface:///b|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface001.php|(209,1,<18,0>,<18,0>),|php+interface:///c|>
  },
  @modifiers={
    <|php+method:///a/foo|,public()>,
    <|php+method:///b/bar|,public()>,
    <|php+method:///c/baz|,public()>,
    
    <|php+method:///d/foo|,public()>,
    <|php+method:///d/bar|,public()>,
    <|php+method:///d/baz|,public()>,
  }
]