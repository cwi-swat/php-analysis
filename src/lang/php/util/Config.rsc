module lang::php::util::Config

import IO;

public loc phploc = |file:///usr/local/php5/bin/php|;

public loc parserLoc = |file:///Users/ruud/git|;
public loc analysisLoc = |file:///Users/ruud/git/php-analysis/|;
	
public str parserMemLimit = "1024M";
public loc rgenLoc = parserLoc + "PHP-Parser/lib/Rascal/AST2Rascal.php";
public loc rgenCwd = parserLoc + "PHP-Parser/lib/Rascal";

public loc baseLoc = |home:///PHPAnalysis|;
public loc parsedDir = baseLoc + "serialized/parsed";
public loc statsDir = baseLoc + "serialized/stats";
public loc corpusRoot = baseLoc + "systems";
public loc countsDir = baseLoc + "serialized/counts";

public bool useBinaries = false;

// parse options
public bool includePhpDocs = true;
public bool includeLocationInfo = true;
public bool resolveNamespaces = true;