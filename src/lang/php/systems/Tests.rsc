@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::systems::Tests

import lang::php::util::Constants;
import lang::php::util::PHCInteraction;
import lang::php::analysis::InlineIncludes;

public loc testsBase = |file:///Users/mhills/Projects/phpsa/tests|;
public set[str] testsPrefixes = { };
public set[str] testsLibs = { };

public map[str,node] loadTests() {
	return getPHPFileMap(testsBase);
}

public node inline(map[str,node] fm, str filename) {
	return inlineIncludesForFile(testsBase, filename, fm, testsPrefixes, testsLibs);
}
