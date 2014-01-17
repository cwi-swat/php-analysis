module lang::php::util::Config

public loc phploc = |file:///usr/bin/php|;

public loc parserLoc = |file:///Users/mhills/Projects/phpsa|;
public loc rgenLoc = parserLoc + "PHP-Parser/lib/Rascal/AST2Rascal.php";
public loc rgenCwd = parserLoc + "PHP-Parser/lib/Rascal";

public loc baseLoc = |home:///PHPAnalysis|;
public loc parsedDir = baseLoc + "serialized/parsed";
public loc statsDir = baseLoc + "serialized/stats";
public loc corpusRoot = baseLoc + "systems";
public loc countsDir = baseLoc + "serialized/counts";

public bool useBinaries = false;

