module lang::php::m3::FillM3
extend lang::php::m3::Core;

import lang::php::m3::Containment;
import lang::php::m3::Aliases;
import lang::php::m3::Uses;

import lang::php::ast::NormalizeAST;
import lang::php::ast::Scopes;

@doc { extract M3 relations from a single PHP script }
public M3 createM3forScript(loc filename, Script script)
{
	M3 m3 = createEmptyM3(filename);

	script = setEmptyModifiersToPublic(script); // set Modifiers when they are not provided, like function => public function
   	m3 = fillDeclarations(m3, script); // fill @declarations and @names	
   	script = propagateDeclToScope(script); // propagate @decl to @scope
	m3 = fillContainment(m3, script); // fill containment with declarations 
	m3 = calculateAliasesFlowInsensitive(m3, script); // fill aliases (currently only for namespace/class/interface/trait names) 
	m3 = calculateUsesFlowInsensitive(m3, script); // fill uses (currently only for namespace/class/interface/trait names) 
	m3 = fillExtendsAndImplements(m3, script); // fill extends, implements and traitUse, by trying to look up class names 
	m3 = fillModifiers(m3, script); // fill modifiers for classes, class fields and class methods 
	m3 = fillPhpDocAnnotations(m3, script); // fill documentation, defined as @phpdoc
	
	return m3;
}


private bool useCacheDefault = true;
// get a system for a specific location
public System getSystem(loc l) = getSystem(l, useCacheDefault);
public System getSystem(loc l, bool useCache) = loadFromCache(l, useCache) ? readSystemFromCache(l) : loadSystem(l, useCache);

public M3 getM3ForDirectory(loc l) = getM3ForSystem(getSystem(l), l);
public M3 getM3ForSystem(System system, loc l) = M3CollectionToM3(getM3CollectionForSystem(system), l);
public M3 M3CollectionToM3 (M3Collection m3s, loc l) = composePhpM3(l, range(m3s));

public M3Collection getM3CollectionForSystem(System system) = (filename:createM3forScript(filename, system[filename]) | filename <- system);

// getSystem helper methods
private bool loadFromCache(loc l, bool useCache) = useCache && cacheFileExists(l);
private System loadSystem(l, true) = loadPHPFiles(l);
private System loadSystem(l, false) { 
	System system = loadPHPFiles(l); 
	writeSystemToCache(system, l); 
	return system;
}
// end of getSystem helper methods

// move to cache function file 
public void writeSystemToCache(System s, loc l) = writeBinaryValueFile(getCacheFileName(l), s);
public System readSystemFromCache(loc l) = readBinaryValueFile(#System, getCacheFileName(l));
public loc getCacheFileName(loc l) = |tmp:///| + "pa" +replaceAll(l.path, "/", "_");
public bool cacheFileExists(loc l) = isFile(getCacheFileName(l));
// end of cache functions

@doc {
When a class is inside a namespace, the only option for the constructor is "__construct"
When a class is defined outside a namespace, "__construct" will be the constructor. If this one
is not available, a method with the class name will be the constructor (and will also be a method)
}
private Script propagateDeclToScope(Script script) {
   	set[str] scopingTypes = {"namespace", "class", "interface", "trait", "function", "method"};
	return annotateWithDeclScopes(script, globalNamespace, scopingTypes);   	
}

@doc {
	fill @declarations and @names
	
	@declarations are provided by the PHP-Parser [@decl]
	@names are the last part of the declaration 
}
private M3 fillDeclarations(M3 m3, Script script) {
	visit (script) {
		case node n: {
			if ( (n@at)? && (n@decl)? ) {
				m3@declarations += {<n@decl, n@at>};
				m3@names += {<n@decl.file, n@decl>};
			}
		}
   	}
   	return m3;
}

private M3 fillExtendsAndImplements(M3 m3, Script script) {
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
   	return m3;
}

private M3 fillModifiers(M3 m3, Script script) {
   	// fill modifiers for classes, class fields and class methods
   	visit (script) {
		case n:class(_,set[Modifier] mfs,_,_,_): 				m3@modifiers += {<n@decl, mf> | mf <- mfs};
		case n:property(set[Modifier] mfs,list[Property] ps): 	m3@modifiers += {<p@decl, mf> | mf <- mfs, p <- ps };	
		case n:method(_,set[Modifier] mfs,_,_,_):				m3@modifiers += {<n@decl, mf> | mf <- mfs};
		
		//traitAlias isn't done here
	}
	return m3;
}

private M3 fillPhpDocAnnotations(M3 m3, Script script) {
	visit (script) {
		case node n:
			if ( (n@decl)? && (n@phpdoc)? ) 
				m3@phpDoc += {<n@decl, n@phpdoc>};
	}
	return m3;
}