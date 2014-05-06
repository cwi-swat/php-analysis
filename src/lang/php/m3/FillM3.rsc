module lang::php::m3::FillM3
extend lang::php::m3::Core;

import lang::php::m3::Containment;
import lang::php::m3::Aliases;
import lang::php::m3::Uses;

import lang::php::ast::Scopes;

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
   	
   	// propagate @decl to @scope
	script = annotateWithDeclScopes(script, globalNamespace);   	
   	
   	iprintln(script);
   	
	// fill containment with declarations
	m3 = fillContainment(m3, script);

	// fill aliases (currently only for namespace/class/interface/trait names)
	m3 = calculateAliasesFlowInsensitive(m3, script);

	// fill uses (currently only for namespace/class/interface/trait names)
	m3 = calculateUsesFlowInsensitive(m3, script);

	// fill extends, implements and traitUse, by trying to look up class names
	visit (script) {
		case c:class(_, _, extends:name(_), implements, body): {			
			m3@extends += {<c@decl, ext> | ext <- m3@uses[extends@at]};
			m3@implements += {<c@decl, impl> | name <- implements, impl <- m3@uses[name@at]};
			
			for (traitUse(names, _) <- body) {
				m3@traitUse += {<c@decl, trait> | name <- names, trait <- m3@uses[name@at]};
			}		
		}
		
		case i:interface(_, extends, _): {
			m3@extends += {<i@decl, ext> | name <- extends, ext <- m3@uses[name@at]};;
		}
		
		case t:trait(_, body): { 
			for (traitUse(names, _) <- body) {
				m3@traitUse += {<c@decl, trait> | name <- names, trait <- m3@uses[name@at]};
			}		
		}
   	}	
   	
   	// fill modifiers for classes, class fields and class methods
   	visit (script) {
		case n:class(_,set[Modifier] mfs,_,_,_): 				m3@modifiers += {<n@decl, mf> | mf <- mfs};
		case n:property(set[Modifier] mfs,list[Property] ps): 	m3@modifiers += {<p@decl, mf> | mf <- mfs, p <- ps };	
		case n:method(_,set[Modifier] mfs,_,_,_):				m3@modifiers += {<n@decl, mf> | mf <- mfs};
		
		//traitAlias isn't done here
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
public M3Collection createM3sFromDirectory(loc l) = createM3sFromDirectory(l, false);

public M3Collection createM3sFromDirectory(loc l, bool useCache) {
	if (!isDirectory(l)) throw AssertionFailed("Location <l> must be a directory");
	if (l.scheme != "file") throw AssertionFailed("Location <l> must be an absolute path, use |file:///|");

	System system = getSystem(l, useCache);
    system = normalizeSystem(system);
    return getM3CollectionForSystem(system);
}

public System getSystem(loc l, bool useCache) {
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
	
	return system;
}

// move to cache function file 
public void writeSystemToCache(System s, loc l) = writeBinaryValueFile(getCacheFileName(l), s);
public System readSystemFromCache(loc l) = readBinaryValueFile(#System, getCacheFileName(l));
public loc getCacheFileName(loc l) = |tmp:///| + "pa" +replaceAll(l.path, "/", "_");
public bool cacheFileExists(loc l) = isFile(getCacheFileName(l));
// end of cache functions
