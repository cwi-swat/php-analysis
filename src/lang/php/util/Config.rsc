@license{
  Copyright (c) 2009-2014 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - mhills@cs.ecu.edu (ECU)}
module lang::php::util::Config

import IO;

public loc phploc = |file:///usr/local/php5/bin/php|;

public loc parserLoc = |file:///Users/mhills/PHPAnalysis|;
public loc analysisLoc = |file:///Users/mhills/PHPAnalysis/rascal|;
	
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
public bool includePhpDocs = false;
public bool includeLocationInfo = false;
public bool resolveNamespaces = false;