@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::signatures::Signatures

import lang::php::analysis::NamePaths;
import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import List;

data SignatureItem
	= functionSig(NamePath namepath, int parameterCount)
	| constSig(NamePath namepath, Expr e)
	| classSig(NamePath namepath)
	| methodSig(NamePath namepath, int parameterCount)
	| classConstSig(NamePath namepath, Expr e)
	;

public anno loc SignatureItem@at;

data Signature
	= fileSignature(loc fileloc, set[SignatureItem] items)
	;
		
public Signature getFileSignature(loc fileloc, Script scr) {
	set[SignatureItem] items = { };
	
	// First, pull out all class definitions
	classDefs = { c | /ClassDef c := scr };
	for (class(cn,_,_,_,cis) <- classDefs) {
		items += classSig(classPath(cn));
		for (mt:method(mn,_,_,mps,_) <- cis) {
			if ( (mt@at)? )
				items += methodSig(methodPath(cn, mn), size(mps))[@at=mt@at];
			else
				items += methodSig(methodPath(cn, mn), size(mps));
		}
		for(constCI(consts) <- cis, const(name,ce) <- consts) {
			items += classConstSig(classConstPath(cn, name), ce);
		}
	}
	
	// Second, get all top-level functions
	for (/f:function(fn,_,fps,_) := scr) {
		if ( (f@at)? ) {
			items += functionSig(functionPath(fn),size(fps))[@at=f@at];
		} else {
			items += functionSig(functionPath(fn),size(fps));
		}
	}

	// TODO: We also want to add global variables here, but need to do this in the
	// right way -- we don't know, at this point, if a name is introduced here for
	// the first time, or is brought in through another include. The only way to
	// know this for sure is either to a) resolve the includes here, or b) determine
	// that there are no includes.
		
	// Finally, get all defined constants
	items += { constSig(constPath(cn),e) | /c:call(name(name("define")),[actualParameter(scalar(string(cn)),false),actualParameter(e,false)]) := scr };
	
	return fileSignature(fileloc, items);
}

public Signature getScriptConstants(loc fileloc, Script scr) {
	set[SignatureItem] items = 
		{ classConstSig(classConstPath(cn, name), ce) | /class(cn,_,_,_,cis) := scr, constCI(consts) <- cis, const(name,ce) <- consts } +
		{ constSig(constPath(cn),e) | /c:call(name(name("define")),[actualParameter(scalar(string(cn)),false),actualParameter(e,false)]) := scr };
	return fileSignature(fileloc, items);
}
		
public map[loc,Signature] getSystemSignatures(System sys) {
	return ( l : getFileSignature(l,sys[l]) | l <- sys );
}

public map[loc,Signature] getConstantSignatures(System sys) {
	return ( l : getScriptConstants(l,sys[l]) | l <- sys );
}

public rel[SignatureItem, loc] getAllDefinedConstants(map[loc fileloc, Script scr] scripts) {
	ssigs = getSystemSignatures(scripts);
	return { < si, l > | fileSignature(l,sis) <- ssigs<1>, 
						 si <- sis, 
						 constSig(cn,e) := si || classConstSig(cln,cn,e) := si };
}

public rel[SignatureItem,loc] getDefinitionsForItem(map[loc fileloc, Script scr] scripts, NamePath itemName) {
	ssigs = getSystemSignatures(scripts);
	return { < si, l > | fileSignature(l,sis) <- ssigs<1>, 
						 si <- sis,
						 si.namepath == itemName }; 
}
