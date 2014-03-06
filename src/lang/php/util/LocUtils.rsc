@license{
  Copyright (c) 2009-2014 CWI
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

@doc{Calculate the actual location of a path given as a string.}
public loc calculateLoc(set[loc] possibleLocs, loc baseLoc, loc rootLoc, str path, bool pathMayBeChanged = true, list[str] ipath = []) {
	qualifiedPath = false;
	set[str] paths = { };
	set[loc] matchedLocs = { };

	// Build the actual path based on the string for the path that we are given.
	// If the path starts with a \ or / character, it is an absolute path, so
	// we look it up from the root. If the path starts with a . (including ..)
	// the path is a relative path, so we will look it up from the base location,
	// which is the location of the script containing the include. One wrinkle here
	// is that this is the "top level" script: if A includes B and B includes C,
	// we use the location of A since the include of C will execute in that context.
	// If the path does not match one of these two options, we currently fall back
	// on matching, but TODO: need to improve library matching in the future.	
	if (size(trim(path)) > 0 && ( path[0] == "/" || path[0] == "\\") ) {
		paths = { (rootLoc + path).path };
		qualifiedPath = true;
	} else if (size(trim(path)) > 0 && ( path[0] == "." ) ) {
		paths = { (baseLoc.parent + path).path };
		qualifiedPath = true;
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
