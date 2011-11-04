@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::systems::Mediawiki

import lang::php::util::Constants;
import lang::php::util::PHCInteraction;
import lang::php::analysis::InlineIncludes;
import IO;
import ValueIO;

public loc mediawiki1612In = |file:///ufs/hills/project/phpsa/mediawiki/mediawiki-1.6.12|;
public loc mediawiki1612Out = |file:///ufs/hills/project/phpsa/working/mediawiki-1.6.12|;
public loc mediawiki1612Inlined = |file:///ufs/hills/project/phpsa/inlined/mediawiki-1.6.12|;

public list[str] mediawiki1612Prefixes = [ "", "includes" ];
public set[str] mediawiki1612Libs = { "Mail.php" };

public void processMediawiki() {
	fm = getPHPFileMap(mediawiki1612In);
	for (fmi <- fm<0>) writeTextValueFile(mediawiki1612Out + fmi, fm[fmi]);
}

public node getMediawikiFile(str filename) {
	if (!mediawikiFileExists(filename)) throw "File does not exist, try processing mediawiki first using processMediawiki()";
	return readTextValueFile(#node, mediawiki1612Out + filename);
}

public bool mediawikiFileExists(str filename) {
	return exists(mediawiki1612Out + filename);
}

public node getInlinedMediawikiFile(str filename) {
	if (!inlinedMediawikiFileExists(filename)) throw "File does not exist, try inlining the file first";
	return readTextValueFile(#node, mediawiki1612Inlined + filename);
}

public bool inlinedMediawikiFileExists(str filename) {
	return exists(mediawiki1612Inlined + filename);
}

public void inline(str filename) {
	if (!mediawikiFileExists(filename)) throw "File does not exist, try processing mediawiki first using processMediawiki()";
	writeTextValueFile(mediawiki1612Inlined + filename, inlineIncludesForFile(filename, mediawiki1612Prefixes, mediawiki1612Libs, getMediawikiFile, mediawikiFileExists));
}
