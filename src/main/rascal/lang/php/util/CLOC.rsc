@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::util::CLOC

import util::ShellExec;
import IO;
import String;
import List;

import lang::php::util::Corpus;
import lang::php::util::Utils;

data ClocResult 
	= clocResult(int files, int blankLines, int commentLines, int sourceLines)
	| noResult()
	;

@doc{
	Compute the source lines of code for a given location. This location
	could be a single file or a directory.
}
public ClocResult phpLinesOfCode(loc l, loc clocPath) {
	pid = createProcess(clocPath.path, args = [l.path]);
	res = readEntireStream(pid);
	killProcess(pid);
	if(/PHP\s+<n1:\d+>\s+<n2:\d+>\s+<n3:\d+>\s+<n4:\d+>/ := res) {
		return clocResult(toInt(n1), toInt(n2), toInt(n3), toInt(n4));
	} else {
		println("Odd, no PHP code found in file <l.path>");
		return noResult();
	}
}
