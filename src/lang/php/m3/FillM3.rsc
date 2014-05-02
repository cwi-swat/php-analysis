module lang::php::m3::FillM3
extend lang::php::m3::Core;

import lang::php::m3::Containment;
import lang::php::m3::Uses;

@doc { extract M3 relations from a single PHP script }
public M3 createM3forScript(loc filename, Script script)
{
	M3 m3 = createEmptyM3(filename);
	
	// fill declarations
	visit (script) {
		case node n: {
			if ( (n@at)? && (n@decl)? ) {
				m3@declarations += {<n@decl, n@at>};
				m3@names += {<n@decl.file, n@decl>};
			}
		}
   	}
   	
   	// if there are no namespaces, or no declarations at all, add global namespace
   	if (!(m3@declarations)? || isEmpty({ ns | <ns,_> <- m3@declarations, isNamespace(ns) })) {
		m3@declarations += {<globalNamespace, l>};
   	}
	  	
	// fill containment with declarations
	m3 = fillContainment(m3, script);

	// fill uses (currently only for namespace/class/interface/trait names)
	m3 = calculateUsesFlowInsensitive(m3, script);

	// fill extends, implements and usesTrait, by trying to look up class names
	visit (script) {
		case c:class(_,_,someName(name(name)),_,_): {
			set[loc] possibleExtends = getPossibleClassesInM3(m3, name);
			m3@extends += {<c@decl, ext> | ext <- possibleExtends};
			fail; // continue this visit, a class can have extends and implements.
		}
		case c:class(_,_,_,list[Name] implements,_): {
			for (name <- [n | name(n) <- implements]) {
				set[loc] possibleImplements = getPossibleInterfacesInM3(m3, name);
				m3@implements += {<c@decl, impl> | impl <- possibleImplements};
			}
		}	
		case c:interface(_,list[Name] implements,_): {
			for (name <- [n | name(n) <- implements]) {
				set[loc] possibleImplements = getPossibleInterfacesInM3(m3, name);
				m3@implements += {<c@decl, impl> | impl <- possibleImplements};
			}
		}
   	}	
   	
   	// fill modifiers for classes, class fields and class methods
   	visit (script) {
		case n:class(_,set[Modifier] mfs,_,_,_): 				m3@modifiers += {<n@decl, mf> | mf <- mfs};
		case n:property(set[Modifier] mfs,list[Property] ps): 	m3@modifiers += {<p@decl, mf> | mf <- mfs, p <- ps };	
		case n:method(_,set[Modifier] mfs,_,_,_):				m3@modifiers += {<n@decl, mf> | mf <- mfs};
	}
   	 
 	// fill documentation, defined as @phpdoc
	visit (script) {
		case node n:
			if ( (n@decl)? && (n@phpdoc)? ) 
				m3@phpDoc += {<n@decl, n@phpdoc>};
	}	
	
	return m3;
}


public M3Collection getM3CollectionForSystem(System system) {
    return (filename:createM3forScript(filename, system[filename]) | filename <- system);
}

@doc{
Synopsis: globs for jars, class files and java files in a directory and tries to compile all source files into an [$analysis/m3] model
}
public M3Collection createM3sFromDirectory(loc l) = createM3sFromDirectory(l, true);

public M3Collection createM3sFromDirectory(loc l, bool useCache) {
	if (!isDirectory(l)) throw AssertionFailed("Location <l> must be a directory");
	if (l.scheme != "file") throw AssertionFailed("Location <l> must be an absolute path, use |file:///|");

	System system = ();
	if (useCache && cacheFileExists(l)) {
		logMessage("Reading <l> from cache.", 2);
		system = readSystemFromCache(l);
	} else {	    
    	system = loadPHPFiles(l);
		logMessage("Writing <l> to cache.", 2);
	   	writeSystemToCache(system, l); 
		logMessage("Writing <l> done.", 2);
	}
    system = normalizeSystem(system);
    return getM3CollectionForSystem(system);
}

// move to cache function file 
public void writeSystemToCache(System s, loc l) = writeBinaryValueFile(getCacheFileName(l), s);
public System readSystemFromCache(loc l) = readBinaryValueFile(#System, getCacheFileName(l));
public loc getCacheFileName(loc l) = |tmp:///| + "pa" +replaceAll(l.path, "/", "_");
public bool cacheFileExists(loc l) = isFile(getCacheFileName(l));
// end of cache functions
