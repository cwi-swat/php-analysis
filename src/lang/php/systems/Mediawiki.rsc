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

public loc mediawiki1612 = |file:///Users/mhills/Projects/phpsa/mediawiki/mediawiki-1.6.12|;
public set[str] mediawiki1612Prefixes = { "includes" };
public set[str] mediawiki1612Libs = { "Mail.php" };

public map[str,node] loadMediawiki() {
	return getPHPFileMap(mediawiki1612);
}

public node inline(map[str,node] fm, str filename) {
	return inlineIncludesForFile(mediawiki1612, filename, fm, mediawiki1612Prefixes, mediawiki1612Libs);
}
