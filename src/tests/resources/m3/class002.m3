m3(|file:///|)[
  @declarations={
    <|php+namespace:///a|,        |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class002.php|(8,12,<3,0>,<3,0>)>,
    <|php+class:///a/x|,          |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class002.php|(22,39,<5,0>,<5,0>)>,
    <|php+method:///a/x/getx|,    |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class002.php|(34,25,<6,0>,<6,0>)>,
    <|php+namespace:///a/b|,      |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class002.php|(63,14,<9,0>,<9,0>)>,
    <|php+class:///a/b/y|,        |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class002.php|(79,41,<11,0>,<11,0>)>,
    <|php+method:///a/b/y/gety|,  |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class002.php|(93,25,<12,0>,<12,0>)>,
    <|php+namespace:///b|,        |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class002.php|(122,12,<15,0>,<15,0>)>,
    <|php+class:///b/z|,          |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class002.php|(136,41,<17,0>,<17,0>)>,
    <|php+method:///b/z/getz|,    |file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class002.php|(150,25,<18,0>,<18,0>)>
  },
  @containment={
    <|php+namespace:///a|,   |php+class:///a/x|>,
    <|php+namespace:///a/b|, |php+class:///a/b/y|>,
    <|php+namespace:///b|,   |php+class:///b/z|>,
    <|php+class:///a/x|,     |php+method:///a/x/getx|>,
    <|php+class:///a/b/y|,   |php+method:///a/b/y/gety|>,
    <|php+class:///b/z|,     |php+method:///b/z/getz|>
  },
  @modifiers={
    <|php+method:///b/z/getz|,   public()>,
	  <|php+method:///a/x/getx|,   public()>,
	  <|php+method:///a/b/y/gety|, public()>
	},
  @uses={}
]