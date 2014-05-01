module lang::php::util::Config

import IO;

public loc phploc = |file:///usr/bin/php|;

public loc parserLoc = |file:///home/basten/devel/workspace/PHP-Parser|;
public loc analysisLoc = |file:///home/basten/devel/workspace/php-analysis|;
	
public str parserMemLimit = "1024M";
public loc rgenLoc = parserLoc + "lib/Rascal/AST2Rascal.php";
public loc rgenCwd = parserLoc + "lib/Rascal";

public loc baseLoc = analysisLoc;
public loc parsedDir = baseLoc + "serialized/parsed";
public loc statsDir = baseLoc + "serialized/stats";
public loc corpusRoot = baseLoc + "systems";
public loc countsDir = baseLoc + "serialized/counts";

public bool useBinaries = false;

// parse options
public bool includePhpDocs = false;
public bool includeLocationInfo = true;
public bool resolveNamespaces = false;