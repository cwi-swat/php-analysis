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

@doc{An exception representing the case where a location is not a valid location
     in the system.}
data RuntimeException = UnavailableLoc(loc l);

@doc{Calculate a loc based on the base loc and an addition to the base loc path.
     This also ensures that the resulting loc is one of the possible locs, else
     an exception is thrown.}
public loc calculateLoc(set[loc] possibleLocs, loc baseLoc, loc rootLoc, str path, bool pathMayBeChanged) {
	list[str] parts = split("/",path);
	while([a*,b,"..",c*] := parts) parts = [*a,*c];
	while([a*,".",c*] := parts) parts = [*a,*c];
	if (parts[0] == "") {
		// This means the first character was a "/", so we have an absolute path
		newLoc = rootLoc + intercalate("/",parts);
		if (newLoc in possibleLocs) return newLoc;
		throw UnavailableLoc(newLoc);
	} else {
		// This means the first character was not a "/", so we have a relative path
		newLoc = baseLoc.parent + intercalate("/",parts);
		if (pathMayBeChanged) throw UnavailableLoc(newLoc);
		if (newLoc in possibleLocs) return newLoc;
		throw UnavailableLoc(newLoc);
	}
}
