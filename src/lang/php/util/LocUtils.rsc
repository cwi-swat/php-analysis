@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::util::LocUtils

import Exception;
import String;
import List;
import Set;

@doc{An exception representing the case where a location is not a valid location
     in the system.}
data RuntimeException = UnavailableLoc(str unavailablePath);

@doc{Calculate a loc based on the base loc and an addition to the base loc path.
     This also ensures that the resulting loc is one of the possible locs, else
     an exception is thrown.}
public loc calculateLoc(set[loc] possibleLocs, loc baseLoc, loc rootLoc, str path, bool pathMayBeChanged = true, list[str] ipath = []) {
	qualifiedPath = false;
	set[str] paths = { };
	set[loc] matchedLocs = { };
	
	// Build the possible paths we need to check: just 1 in the case of a qualified path,
	// but multiple paths if we are consulting the include path
	if (size(trim(path)) > 0 && ( path[0] == "/" || path[0] == "\\") ) {
		paths = { (rootLoc + path).path };
		qualifiedPath = true;
	//} else if (size(trim(path)) > 0 && ( path[0] == "." ) ) {
	//	paths = { (baseLoc.parent + path).path };
	//	qualifiedPath = true;
	//} else if (size(trim(path)) > 0) {
	//	paths = { ip + "/" + path | ip <- ipath } + ((baseLoc.parent + path).path); 		
	} else {
		throw UnavailableLoc(path);
	}

	// If the path is not qualified, meaning we look at the include path, but we may have
	// changed the include path, just fall back to matching -- don't even try to look up the
	// file, it could be in any directory
	if (!qualifiedPath && pathMayBeChanged)
		throw UnavailableLoc(path);
		
	// For each possible path, see if we can find it
	for (p <- paths) {
		list[str] parts = split("/",p);
		while([a*,b,"..",c*] := parts) parts = [*a,*c];
		while([a*,".",c*] := parts) parts = [*a,*c];
		newPath = intercalate("/", parts);

		// performed a malformedness check -- if we throw while trying
		// to create the path, rethrow saying this loc is unavailable
		try {
			checkMalformed = (newPath[0] == "/") ? |home://<newPath>| : |home:///<newPath>|;
		} catch _ : {
			continue;
		}

		// Create the new loc and look it up, if we find it as a file we know exists
		// return it		
		newLoc = (newPath[0] == "/") ? |home://<newPath>| : |home:///<newPath>|;
		if (newLoc in possibleLocs) matchedLocs += newLoc;
	}
	
	if (size(matchedLocs) == 1) return getOneFrom(matchedLocs);
	throw UnavailableLoc(path);
}
