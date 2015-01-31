m3(|file:///|)[
  @declarations={
    <|php+namespace:///a|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(8,12,<3,0>,<3,0>)>,
    <|php+class:///a/c|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(22,236,<5,0>,<5,0>)>,
    <|php+classConstant:///a/c/c|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(42,7,<6,0>,<6,0>)>,
    <|php+field:///a/c/pub|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(62,4,<7,0>,<7,0>)>,
    <|php+field:///a/c/priv|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(80,5,<8,0>,<8,0>)>,
    <|php+field:///a/c/pro|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(101,4,<9,0>,<9,0>)>,
    <|php+method:///a/c/pubfunc|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(109,44,<11,0>,<11,0>)>,
    <|php+methodParam:///a/c/pubfunc/param1|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(133,7,<11,0>,<11,0>)>,
    <|php+methodParam:///a/c/pubfunc/param2|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(142,7,<11,0>,<11,0>)>,
    <|php+method:///a/c/privfunc|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(158,46,<12,0>,<12,0>)>,
    <|php+methodParam:///a/c/privfunc/param1|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(184,7,<12,0>,<12,0>)>,
    <|php+methodParam:///a/c/privfunc/param2|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(193,7,<12,0>,<12,0>)>,
    <|php+method:///a/c/profunc|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(209,47,<13,0>,<13,0>)>,
    <|php+methodParam:///a/c/profunc/param1|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(236,7,<13,0>,<13,0>)>,
    <|php+methodParam:///a/c/profunc/param2|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(245,7,<13,0>,<13,0>)>,
    
    <|php+namespace:///a/b|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(260,14,<16,0>,<16,0>)>,
    <|php+class:///a/b/c|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(276,263,<18,0>,<18,0>)>,
    <|php+classConstant:///a/b/c/c|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(302,7,<19,0>,<19,0>)>,
    <|php+field:///a/b/c/pub|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(322,4,<20,0>,<20,0>)>,
    <|php+field:///a/b/c/priv|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(340,5,<21,0>,<21,0>)>,
    <|php+field:///a/b/c/pro|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(361,4,<22,0>,<22,0>)>,
    <|php+method:///a/b/c/pubfunc|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(372,50,<24,0>,<24,0>)>,
    <|php+methodParam:///a/b/c/pubfunc/param1|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(402,7,<24,0>,<24,0>)>,
    <|php+methodParam:///a/b/c/pubfunc/param2|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(411,7,<24,0>,<24,0>)>,
    <|php+method:///a/b/c/privfunc|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(427,52,<25,0>,<25,0>)>,
    <|php+methodParam:///a/b/c/privfunc/param1|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(459,7,<25,0>,<25,0>)>,
    <|php+methodParam:///a/b/c/privfunc/param2|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(468,7,<25,0>,<25,0>)>,
    <|php+method:///a/b/c/profunc|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(484,53,<26,0>,<26,0>)>,
    <|php+methodParam:///a/b/c/profunc/param1|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(517,7,<26,0>,<26,0>)>,
    <|php+methodParam:///a/b/c/profunc/param2|,|file:///Users/ruud/git/php-analysis/src/tests/resources/m3/class003.php|(526,7,<26,0>,<26,0>)>
  },
  @containment={
    <|php+namespace:///a|,     |php+class:///a/c|>,
    <|php+namespace:///a/b|,   |php+class:///a/b/c|>,

    <|php+class:///a/c|, 		|php+classconstant:///a/c/c|>,
    <|php+class:///a/c|, 		|php+field:///a/c/pub|>,
    <|php+class:///a/c|, 		|php+field:///a/c/priv|>,
    <|php+class:///a/c|, 		|php+field:///a/c/pro|>,
    <|php+class:///a/c|, 		|php+method:///a/c/pubfunc|>,
    <|php+class:///a/c|, 		|php+method:///a/c/privfunc|>,
    <|php+class:///a/c|, 		|php+method:///a/c/profunc|>,

    <|php+method:///a/c/pubfunc|,   |php+methodparam:///a/c/pubfunc/param1|>,
    <|php+method:///a/c/pubfunc|,   |php+methodparam:///a/c/pubfunc/param2|>,
    <|php+method:///a/c/privfunc|,  |php+methodparam:///a/c/privfunc/param1|>,
    <|php+method:///a/c/privfunc|,  |php+methodparam:///a/c/privfunc/param2|>,
    <|php+method:///a/c/profunc|,   |php+methodparam:///a/c/profunc/param1|>,
    <|php+method:///a/c/profunc|,   |php+methodparam:///a/c/profunc/param2|>,

    <|php+class:///a/b/c|, 		|php+classconstant:///a/b/c/c|>,
    <|php+class:///a/b/c|, 		|php+field:///a/b/c/pub|>,
    <|php+class:///a/b/c|, 		|php+field:///a/b/c/priv|>,
    <|php+class:///a/b/c|, 		|php+field:///a/b/c/pro|>,
    <|php+class:///a/b/c|, 		|php+method:///a/b/c/pubfunc|>,
    <|php+class:///a/b/c|, 		|php+method:///a/b/c/privfunc|>,
    <|php+class:///a/b/c|, 		|php+method:///a/b/c/profunc|>,
    
    <|php+method:///a/b/c/pubfunc|,   |php+methodparam:///a/b/c/pubfunc/param1|>,
    <|php+method:///a/b/c/pubfunc|,   |php+methodparam:///a/b/c/pubfunc/param2|>,
    <|php+method:///a/b/c/privfunc|,  |php+methodparam:///a/b/c/privfunc/param1|>,
    <|php+method:///a/b/c/privfunc|,  |php+methodparam:///a/b/c/privfunc/param2|>,
    <|php+method:///a/b/c/profunc|,   |php+methodparam:///a/b/c/profunc/param1|>,
    <|php+method:///a/b/c/profunc|,   |php+methodparam:///a/b/c/profunc/param2|>
  },
  @modifiers={
    <|php+class:///a/b/c|,          final()>,
    
    <|php+method:///a/c/privfunc|,  private()>,
    <|php+method:///a/c/pubfunc|,   public()>,
    <|php+method:///a/c/profunc|,   protected()>,
    
    <|php+field:///a/c/pub|,        public()>,
    <|php+field:///a/c/priv|,       private()>,
    <|php+field:///a/c/pro|,        protected()>,
    
    <|php+method:///a/b/c/profunc|, protected()>,
    <|php+method:///a/b/c/profunc|, final()>,
    <|php+method:///a/b/c/privfunc|,final()>,
    <|php+method:///a/b/c/privfunc|,private()>,
    <|php+method:///a/b/c/pubfunc|, final()>,
    <|php+method:///a/b/c/pubfunc|, public()>,
    
    <|php+field:///a/b/c/pub|,      public()>,
    <|php+field:///a/b/c/priv|,     private()>,
    <|php+field:///a/b/c/pro|,      protected()>
	},
  @uses={}
]