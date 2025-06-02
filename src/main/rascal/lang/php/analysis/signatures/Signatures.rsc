@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
		for(classConst(consts,_,_,_) <- cis, const(cn,ce) <- consts) {
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
		{ classConstSig(classConstPath(cln, cn), ce) | /class(cln,_,_,_,cis,_) := scr, classConst(consts,_,_,_) <- cis, const(cn,ce) <- consts } +
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
