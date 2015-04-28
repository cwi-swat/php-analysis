module lang::php::analysis::dataflow::ReachingDefs

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::Label;
import lang::php::analysis::names::AnalysisNames;

data DefValue 
	= scalarValue(Scalar s) 
	| unknownValue()
	;

public rel[Lab, AnalysisName, DefValue] reachingDefs(CFG graph) {
	rel[AnalysisName, DefValue] getDefs(Expr e) {
		switch(e) {
			case assign(tgt, av) : {
				if (scalar(sv) := av && encapsed(_) !:= sv) {
					return { < tgtName, scalarValue(sv) > | tgtName <- computeName(tgt) };
				} else {
					return { < varName(s), unknownValue() > | tgtName <- computeName(tgt) };
				}
			}
	
			case refAssign(var(name(name(s))), av) : {
				if (scalar(sv) := av && encapsed(_) !:= sv) {
					return { < tgtName, scalarValue(sv) > | tgtName <- computeName(tgt) };
				} else {
					return { < varName(s), unknownValue() > | tgtName <- computeName(tgt) };
				}
			}
	
			case assignWOp(var(name(name(s))), av, _) : {
				if (scalar(sv) := av && encapsed(_) !:= sv) {
					return { < tgtName, scalarValue(sv) > | tgtName <- computeName(tgt) };
				} else {
					return { < varName(s), unknownValue() > | tgtName <- computeName(tgt) };
				}
			}
	
			default : {
				return { };
			}
		}
	}
	
	public rel[Lab, AnalysisName, DefValue] getDefs(CFGNode n) {
		switch(n) {
			case exprNode(Expr e, Lab l) : {
				return { <l,x,v> | <x,v> <- getDefs(e) };
			}
			
			case foreachAssignKey(Expr expr, Lab l) : {
				if (var(name(name(s))) := expr) {
					return { < l, varName(s), unknownValue() > };
				}
			}
			
			case foreachAssignValue(Expr expr, Lab l) : {
				if (var(name(name(s))) := expr) {
					return { < l, varName(s), unknownValue() > };
				}
			}
	
			case basicBlock(nl) : {
				return { *getDefs(ni) | ni <- nl };
			}
			
			case actualProvided(str paramName, bool refAssign) : {
				return { < l, varName(paramName), unknownValue() > };
			}
			
			case actualNotProvided(str paramName, Expr expr, bool refAssign) : {
				if (scalar(sv) := expr && encapsed(_) !:= sv) {
					return { < l, varName(paramName), scalarValue(sv) > };
				} else {
					return { < l, varName(paramName), unknownValue() > };
				}
			}
	
			default : {
				return { };
			}
		}
	}
	
	allNames = { an | n <- cfg.nodes,  < l, an, dv > <- getDefs(n) }; 
	
}



public rel[DefName, DefValue, Lab] getDefs(CFG cfg) {
	return { *getDefs(n) | n <- cfg.nodes };
}

public set[Def] extractDefs(CFG cfg) {
	
}