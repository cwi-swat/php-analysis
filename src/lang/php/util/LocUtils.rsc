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
import IO;

@doc{An exception representing the case where a location is not a valid location
     in the system.}
data RuntimeException = UnavailableLoc(str unavailablePath);

data Branch = root(set[Branch] branches) | branch(str name, set[Branch] branches) | file(str name, loc at);

public Branch buildBranch(loc l) {
	if (isFile(l)) {
		return file(l.file, l);
	} else if (isDirectory(l)) {
		return branch(l.file, { buildBranch(li) | li <- l.ls });
	}
}

public Branch buildSiteTree(loc baseLoc) {
	return root({buildBranch(l) | l <- baseLoc.ls});
}

public list[str] pathParts(loc l, loc baseLoc) {
	if (isFile(l)) return pathParts(l.parent, baseLoc);
	
	list[str] res = [ ];
	try {
		while (l != baseLoc) {
			res = res + l.file;
			l = l.parent;
		}
	} catch : {
		;
	}
	return reverse(res);
}

public tuple[Branch match, list[Branch] parents] findStartingBranch(Branch b, list[str] parts, list[Branch] parents = [ ]) {
	if (!isEmpty(parts)) {
		part = head(parts);
		matches = { bi | bi <- b.branches, bi.name == part };
		if (size(matches) == 1) {
			return findStartingBranch(getOneFrom(matches), tail(parts), parents = parents + b);
		}
		throw UnavailableLoc(intercalate("/", parts));
	}
	return < b, parents >;
} 

public loc walkBranches(Branch br, list[Branch] parents, str pathexp) {
	int idx = findFirst(pathexp, "/");
	if (idx == -1) {
		// No more path separators, the pathexp we have should be the
		// name of the file we are looking for
		matches = { bi | bi <- br.branches, bi.name == pathexp };
		if (size(matches) == 1 && file(_, at) := getOneFrom(matches)) {
			return at;
		}
		throw UnavailableLoc(pathexp);
	} else {
		pathpart = pathexp[0..idx];
		pathrest = pathexp[idx+1..];
		if (pathpart == "..") {
			// This is for paths like ../and/something/else
			return walkBranches(parents[-1],parents[..-1],pathrest);
		} else if (pathpart == ".") {
			// This is for paths like ./and/something/else
			return walkBranches(br, parents, pathrest);
		} else if (pathpart == "") {
			// This is for paths like //and/something/else (CHECK THIS)
			return walkBranches(br, parents, pathrest);
		} else {
			// This is for other cases, like and/something/else
			matches = { bi | bi <- br.branches, bi.name == pathpart };
			if (size(matches) == 1 && bi:branch(_, _) := getOneFrom(matches)) {
				return walkBranches(bi, parents + br, pathrest);
			}
			throw UnavailableLoc(pathexp);
		}
	}
}

@doc{Calculate the actual location of a path given as a string.}
public loc calculateLoc(set[loc] possibleLocs, loc baseLoc, loc rootLoc, str path, bool pathMayBeChanged = true, list[str] ipath = []) {
	qualifiedPath = false;
	set[str] paths = { };
	set[loc] matchedLocs = { };

	if (size(trim(path)) > 0 && ( path[0] == "/" || path[0] == "\\") ) {
		// If the path starts with \ or / we compute the loc for file `path`
		// starting at the root of the site.
		paths = { (rootLoc + path).path };
		qualifiedPath = true;
	} else if (size(trim(path)) > 0 && ( path[0] == "." ) ) {
		// If the path starts with . it could be either . or ..
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

public loc calculateLoc(loc baseLoc, loc rootLoc, str path, Branch site, bool pathMayBeChanged = true, list[str] ipath = []) {
	try {
		path = trim(path);
		if (size(path) > 0 && ( path[0] == "/" || path[0] == "\\") ) {
			// Absolute path, we look this up directly
			return walkBranches(site, [], path[1..]);
		} else if (size(path) > 0 && ( path[0] == "." ) ) {
			// Relative path, we look this up directly
			< br, parents > = findStartingBranch(site, pathParts(baseLoc, rootLoc));
			return walkBranches(br, parents, path);
		} else if (size(path) > 0 && !pathMayBeChanged) {
			// Look this up using the include path, then the script directory; we have no
			// way of knowing the current working directory, so we will just fall back
			// to matching in that case
			for (pi <- ipath) {
				try {
					if (trim(pi) == "") {
						continue;
					} else if ("." == pi) {
						< br, parents > = findStartingBranch(site, pathParts(baseLoc, rootLoc));
						return walkBranches(br, parents, path);
					} else if (".." == pi) {
						< br, parents > = findStartingBranch(site, pathParts(baseLoc, rootLoc)[..-1]);
						return walkBranches(br, parents, path);
					} else if ("/" == pi[0] || "\\" == pi[0]) {
						< br, parents > = findStartingBranch(site, pathParts(rootLoc + pi, rootLoc));
						return walkBranches(br, parents, path);
					} else {
						< br, parents > = findStartingBranch(site, pathParts(baseLoc + pi, rootLoc));
						return walkBranches(br, parents, path);
					}
				} catch : {
					continue;
				}
			}
			< br, parents > = findStartingBranch(site, pathParts(baseLoc, rootLoc));
			return walkBranches(br, parents, path);
		} else {
			throw UnavailableLoc(path);
		}
	} catch : {
		throw UnavailableLoc(path);
	}
}
