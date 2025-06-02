@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module tests::lang::php::pp::PrettyPrinter
// note: the down side of this test is that it is hard to automate this test, 
// because different inputs (of the same semantic value) can have a general pretty print.

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::pp::PrettyPrinter;
import lang::php::config::Config;
import lang::php::util::Utils;

import IO;
import List;
import String;

private loc srcFolder = parserLoc + "PHP-Parser/test/code/parser";
private loc outputFolder = analysisLoc + "src/tests/resources/pp";
private str ppFileExtension = "phppp";
// these files fail to parse, ignore them
private list[str] ignoreFiles = [ "constant_expr.test", "assign.test", "int.test", "generator.test" ];

@doc { parse test files and pretty print them, (create php+phppp files) }
public void createPrettyPrintFiles() 
{
	if (isEmpty(outputFolder.ls)) {
		createPhpFilesFromPhpParserTestFiles();
	}
	
	System system = loadPHPFiles(outputFolder);
	for (fileLoc <- system.files) {
		loc prettyPrintedFile = phpFileToPp(fileLoc); 
		str prettyPrintedCode = pp(system.files[fileLoc]);
		
		writeFile(prettyPrintedFile, prettyPrintedCode);	
	}
}

@doc{ read PHP-Parser parser test files to create test files for pretty print }
public void createPhpFilesFromPhpParserTestFiles() 
{
	logMessage("Create php test files from PHP-Parser parser test files...", 2);
	for (file <- getPhpParserTestFiles()) {
		writeCodeFromTestFileToPhpFile(file);
	}
	logMessage("Done.", 2);
}

private loc phpFileToPp(loc f) = toLocation("<f>"[1..][0..-5]+".<ppFileExtension>");

private void writeCodeFromTestFileToPhpFile(loc l) {
	list[str] lines = readFileLines(l);
	
	str title = top(lines);
	lines = pop(lines)[1];
	
	str out = getCodeFromFile(lines);
	loc f = outputFolder + "<l.parent.file>_<replaceAll(title, " ", "")>.php";
	writeFile(f, out);	
}

private list[loc] getPhpParserTestFiles() = removeIgnored(crawl(srcFolder, "test"));
private list[loc] removeIgnored(list[loc] files) = [ f | f <- files, !(f.file in ignoreFiles) ];
private list[loc] getPhpSourceFiles() = crawl(outputFolder, "php");
private list[loc] getPrettyPrintedFiles() = crawl(outputFolder, ppFileExtension);


private list[loc] crawl(loc dir, str suffix){
  res = [];
  for(str entry <- listEntries(dir)){
      loc sub = dir + entry;   
      if(isDirectory(sub)) {
          res += crawl(sub, suffix);
      } else {
	      if(endsWith(entry, suffix)) { 
	         res += [sub]; 
	      }
      }
  };
  return res;
}

@doc {
format of test file:

Title
-----
code(1)
-----
result(1)
-----
code(2)
-----
result(2)
-----
code(3)
-----
result(3)


What we want is:

code(1)
code(2)
code(3)

}
private str getCodeFromFile(list[str] lines) {
	str startToken = "-----";
	list[list[str]] tests = [];
	list[str] \test = [];
	
	for (line <- lines) {
		if (line == startToken) {
			tests += [\test];
			\test = [];
		} else {
			\test += [line];
		}
	}
	
	// only get the code , discard the rest
	str out = "";
	for (strings <- tests[1,3..]) {
		for (s <- strings) {
			out += s + "\n";
		}
	}
	
	return out;
}