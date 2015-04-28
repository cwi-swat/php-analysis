module lang::php::analysis::names::AnalysisNames

import lang::php::ast::AbstractSyntax;
import lang::php::pp::PrettyPrinter;

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
public AnalysisName computeName(NameOrExpr e) {
	if (name(name(s)) := e) {
		return varName(s);
	} else if (expr(ie) := e) {
		return computeName(ie);
	}
}

public AnalysisName computeName(Expr e) {
	switch(e) {
		case var(name(name(s))) : {
			return varName(s);
		}
		
		case var(expr(_)) : {
			return unknownVar();
		}
		
		case propertyFetch(pt, name(name(p))) : {
			ptname = computeName(pt);
			if (ptname is compoundName) {
				return compoundName(ptname.parts + fieldName(p));
			} else {
				return compoundName([ptname, fieldName(p)]);
			}
		}

		case propertyFetch(pt, expr(_)) : {
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
			return unknownName();
		}
	}
}