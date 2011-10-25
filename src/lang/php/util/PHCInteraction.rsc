@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::util::PHCInteraction

import util::ShellExec;
import IO;
import ValueIO;
import String;
import Set;

import lang::php::util::NodeInfo;

loc phpLoc = |file:///Users/mhills/local/bin/phc|;
map[str,str] env = ( "PATH" : "/usr/local/bin:/usr/local/sbin:/Users/mhills/local/bin:/usr/bin:/bin:/usr/sbin:/sbin");
loc workingDir = |file:///Users/mhills/Projects/phpsa/ast2rascal|;

public node loadPHPFile(loc l) {
	println("Loading PHP file <l>");
	PID pid = createProcess("./runit", ["<l.path>"], env, workingDir);
	str phcOutput = "";
	while (! endsWith(phcOutput, "***DONE***") ) phcOutput = phcOutput + readFrom(pid);
	phcOutput = substring(phcOutput,0,size(phcOutput)-10);
	node res = readTextValueString(#node, phcOutput);
	killProcess(pid);
	return res;
}

public map[loc,node] loadPHPFiles(loc l) {

	list[loc] entries = [ l + e | e <- listEntries(l) ];
	list[loc] dirEntries = [ e | e <- entries, isDirectory(e) ];
	list[loc] phpEntries = [ e | e <- entries, e.extension in {"php","inc"} ];

	map[loc,node] phpNodes = ( e : loadPHPFile(e) | e <- phpEntries);
	for (d <- dirEntries) phpNodes = phpNodes + loadPHPFiles(d);
	
	return phpNodes;
}

public map[str,node] getPHPFileMap(loc l) {
	m = loadPHPFiles(l);
	return ( substring(i.path,size(l.path)+1) : m[i] | i <- m<0> );
}

public map[str,node] getPHPFileMap(map[loc,node] loadedFiles) {
	return ( substring(i.path,size(l.path)+1) : loadedFiles[i] | i <- loadedFiles<0> );
}
