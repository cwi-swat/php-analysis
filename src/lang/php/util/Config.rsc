module lang::php::util::Config

public loc phploc = |file:///usr/bin/php|;

public loc parserLoc = |file:///Users/mhills/Projects/phpsa|;
public loc rgenLoc = parserLoc + "PHP-Parser/lib/Rascal/AST2Rascal.php";
public loc rgenCwd = parserLoc + "PHP-Parser/lib/Rascal";

public loc baseLoc = |file:///Users/mhills/Projects/phpsa|;
public loc parsedDir = baseLoc + "parsed";
public loc statsDir = baseLoc + "stats";
public loc corpusRoot = baseLoc + "corpus";
public loc countsDir = baseLoc + "counts";

public bool useBinaries = true;

