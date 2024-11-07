@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::util::Config

@doc{Indicates whether to use the parser contained in a distributed jar file or from the directory given below}
public bool usePhpParserJar = false;

@doc{The location of the PHP executable}
public loc phploc = |file:///usr/local/php5/bin/php|;

@doc{The base install location for the PHP-Parser project}
public loc parserLoc = |file:///Users/yourid/PHPAnalysis/PHP-Parser|;

@doc{The base install location for the php-analysis project}
public loc analysisLoc = |file:///Users/yourid/PHPAnalysis/php-analysis/|;
	
@doc{The memory limit for PHP when the parser is run}
public str parserMemLimit = "1024M";

@doc{The location of the AST2Rascal.php file, inside the PHP-Parser directories}
public str astToRascal = "lib/Rascal/AST2Rascal.php";

@doc{The working directory for when the parser runs}
public loc parserWorkingDir = (parserLoc + astToRascal).parent;

@doc{The base location for the corpus and any serialized files}
public loc baseLoc = |home:///PHPAnalysis|;

@doc{Where to put the binary representations of parsed systems}
public loc parsedDir = baseLoc + "serialized/parsed";

@doc{Where to put the binary representations of extracted statistics}
public loc statsDir = baseLoc + "serialized/stats";

@doc{Where the PHP sources for the corpus reside}
public loc corpusRoot = baseLoc + "systems";

@doc{Where to put extracted counts (e.g., SLOC)}
public loc countsDir = baseLoc + "serialized/counts";

@doc{This should only ever be true if we don't have source, we only have the extracted binaries for parsed systems}
public bool useBinaries = false;

@doc{Parser options, setting these to true can result in additional annotations on ASTs}
public bool includePhpDocs = false;
public bool includeLocationInfo = false;
public bool resolveNamespaces = false;

@doc{Debugging options}
@logLevel {
	Log level 0 => no logging;
	Log level 1 => main logging;
	Log level 2 => debug logging;
}
public int logLevel = 2;
