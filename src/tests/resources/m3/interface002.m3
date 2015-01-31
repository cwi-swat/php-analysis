m3(|file:///|)[
  @declarations={
    <|php+namespace:///alpha|,        |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface002.php|(6,16,<2,0>,<2,0>)>,
    <|php+constant:///alpha/b|,       |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface002.php|(30,5,<4,0>,<4,0>)>,
    <|php+interface:///alpha/a|,      |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface002.php|(38,51,<6,0>,<6,0>)>,
    <|php+classConstant:///alpha/a/b|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface002.php|(62,24,<8,0>,<8,0>)>,
    <|php+namespace:///beta|,         |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface002.php|(91,15,<11,0>,<11,0>)>,
    <|php+class:///beta/b|,           |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface002.php|(296,82,<22,0>,<22,0>)>
  },
  @containment={
    <|php+namespace:///alpha|,  |php+interface:///alpha/a|>,
    <|php+namespace:///beta|,   |php+class:///beta/b|>,

    <|php+interface:///alpha/a|, |php+classConstant:///alpha/a/b|>,
    <|php+namespace:///alpha|, |php+constant:///alpha/b|>
  },
  @uses={
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface002.php|(188,3,<16,0>,<16,0>),|php+constant:///beta/a/b|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface002.php|(198,10,<17,0>,<17,0>),|php+class:///alpha/a|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface002.php|(198,10,<17,0>,<17,0>),|php+interface:///alpha/a|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface002.php|(210,1,<17,0>,<17,0>),|php+classConstant:///alpha/a/b|>,
    <|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/interface002.php|(315,10,<22,0>,<22,0>),|php+interface:///alpha/a|>
  },
  @modifiers={
  }
]