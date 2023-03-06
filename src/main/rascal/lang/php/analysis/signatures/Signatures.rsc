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

data ParamInfo = paramInfo(str paramName, bool isRef) | paramInfo(str paramName, str givenType, bool isRef);

data SignatureItem(loc at=|unknown:///|)
	= functionSig(loc namepath, int parameterCount)
	| functionSig(loc namepath, list[ParamInfo] parameterInfo) 
	| constSig(loc namepath, Expr e)
	| classSig(loc namepath)
	| methodSig(loc namepath, int parameterCount)
	| methodSig(loc namepath, list[ParamInfo] parameterInfo)
	| classConstSig(loc namepath, Expr e)
	;

data Signature
	= fileSignature(loc fileloc, set[SignatureItem] items)
	;
		
public Signature getFileSignature(loc fileloc, Script scr, bool buildInfo=false) {
	set[SignatureItem] items = { };
	
	// First, pull out all class definitions
	classDefs = { c | /ClassDef c := scr };
	for (class(cln,_,_,_,cis,_) <- classDefs) {
		items += classSig(classPath(cln));
		for (mt:method(mn,_,_,mps,_,_,_) <- cis) {
			if (buildInfo) {
				if ( (mt.at.scheme != "unknown") ) {
					items += methodSig(methodPath(cln, mn), [ paramInfo(mp.paramName, mp.byRef) | mp <- mps ])[at=mt.at];
				} else {
					items += methodSig(methodPath(cln, mn), [ paramInfo(mp.paramName, mp.byRef) | mp <- mps ]);
				}
			} else {
				if ( (mt.at.scheme != "unknown") ) {
					items += methodSig(methodPath(cln, mn), size(mps))[at=mt.at];
				} else {
					items += methodSig(methodPath(cln, mn), size(mps));
				}
			}
		}
		for(constCI(consts,_,_) <- cis, const(cn,ce) <- consts) {
			items += classConstSig(classConstPath(cln, cn), ce);
		}
	}
	
	// Second, get all top-level functions
	for (/f:function(fn,_,fps,_,_,_) := scr) {
		if (buildInfo) {
			if ( (f.at.scheme != "unknown") ) {
				items += functionSig(functionPath(fn), [ paramInfo(fp.paramName, fp.byRef) | fp <- fps ])[at=f.at];
			} else {
				items += functionSig(functionPath(fn), [ paramInfo(fp.paramName, fp.byRef) | fp <- fps ]);
			}
		} else {
			if ( (f.at.scheme != "unknown") ) {
				items += functionSig(functionPath(fn), size(fps))[at=f.at];
			} else {
				items += functionSig(functionPath(fn), size(fps));
			}
		}
	}

	// TODO: We also want to add global variables here, but need to do this in the
	// right way -- we don't know, at this point, if a name is introduced here for
	// the first time, or is brought in through another include. The only way to
	// know this for sure is either to a) resolve the includes here, or b) determine
	// that there are no includes.
		
	// Finally, get all defined constants
	items += { constSig(constPath(cn),e) | /call(name(name("define")),[actualParameter(scalar(string(cn)),false,false,_),actualParameter(e,false,false,_)]) := scr };
	
	return fileSignature(fileloc, items);
}

public Signature getScriptConstants(loc fileloc, Script scr) {
	set[SignatureItem] items = 
		{ classConstSig(classConstPath(cln, cn), ce) | /class(cln,_,_,_,cis,_) := scr, constCI(consts,_,_) <- cis, const(cn,ce) <- consts } +
		{ constSig(constPath(cn),e) | /call(name(name("define")),[actualParameter(scalar(string(cn)),false,false,_),actualParameter(e,false,false,_)]) := scr };
	return fileSignature(fileloc, items);
}
		
public map[loc,Signature] getSystemSignatures(System sys) {
	return ( l : getFileSignature(l,sys.files[l]) | l <- sys.files );
}

public map[loc,Signature] getConstantSignatures(System sys) {
	return ( l : getScriptConstants(l,sys.files[l]) | l <- sys.files );
}

public rel[SignatureItem, loc] getAllDefinedConstants(System scripts) {
	ssigs = getSystemSignatures(scripts);
	return { < si, l > | fileSignature(l,sis) <- ssigs<1>, 
						 si <- sis,
						 si is constSig || si is classConstSig };
}

public rel[SignatureItem,loc] getDefinitionsForItem(System scripts, loc itemName) {
	ssigs = getSystemSignatures(scripts);
	return { < si, l > | fileSignature(l,sis) <- ssigs<1>, 
						 si <- sis,
						 si.namepath == itemName }; 
}
