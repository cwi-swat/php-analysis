@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::analysis::names::AnalysisNames

import lang::php::ast::AbstractSyntax;
import lang::php::pp::PrettyPrinter;

import IO;
import Exception;

data AnalysisName
	= nameSet(set[AnalysisName] possibleNames)
	| fieldName(str fieldName) 
	| varName(str varName) 
	| compoundName(list[AnalysisName] parts)
	| indexed()
	| unknownVar()
	| unknownField()
	;
	
public set[AnalysisName] knownNames(AnalysisName an) {
	// TODO: Cut off parts in compound names that we don't need
	if (unknownField() := an) {
		return { };
	} else if (unknownVar() := an) {
		return { };
	} else if (compoundName(parts) := an && unknownVar() := parts[0]) {
		return { };
	} else if (compoundName(parts) := an) {
		return knownNames(parts[0]);
	} else if (nameSet(pns) := an) {
		return { *knownNames(pn) | pn <- pns };
	}
	return { an };
}  

@doc{
	Compute the 
}
public AnalysisName computeName(NameOrExpr e) {
	if (name(name(s)) := e) {
		return varName(s);
	} else if (expr(ie) := e) {
		// TODO: Do we need another layer here?
		return computeName(ie);
	}
	throw UnavailableInformation(); // TODO: Do we even need this module? Clean up if not needed...
}

@doc{
	Compute the name represented by an expression. This can be a var name for simple
	cases, like $x, but can also be compound names if we have more complex expressions,
	like $x.y or $x.y.z.	
}
public AnalysisName computeName(Expr e) {
	switch(e) {
		case var(name(name(s))) : {
			return varName(s);
		}
		
		case var(expr(_)) : {
			return unknownVar();
		}
		
		case propertyFetch(pt, name(name(p)), bool _) : {
			ptname = computeName(pt);
			if (ptname is compoundName) {
				return compoundName(ptname.parts + fieldName(p));
			} else {
				return compoundName([ptname, fieldName(p)]);
			}
		}

		case propertyFetch(pt, expr(_), bool _) : {
			ptname = computeName(pt);
			if (ptname is compoundName) {
				return compoundName(ptname.parts + unknownField());
			} else {
				return compoundName([ptname, unknownField()]);
			}
		}

		case staticPropertyFetch(pt, name(name(p))) : {
			ptname = computeName(pt);
			if (ptname is compoundName) {
				return compoundName(ptname.parts + fieldName(p));
			} else {
				return compoundName([ptname, fieldName(p)]);
			}
		}

		case staticPropertyFetch(pt, expr(_)) : {
			ptname = computeName(pt);
			if (ptname is compoundName) {
				return compoundName(ptname.parts + unknownField());
			} else {
				return compoundName([ptname, unknownField()]);
			}
		}
		
		case fetchArrayDim(v, _) : {
			vname = computeName(v);
			if (vname is compoundName) {
				return compoundName(vname.parts + indexed());
			} else {
				return compoundName([vname, indexed()]);
			}
		}
		
		default : {
			println("WARNING: No support for the following name: <pp(e)>");
			return unknownVar();
		}
	}
}