module lang::php::analysis::dataflow::ReachingDefs

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::Label;

data DefValue = scalarDef(Scalar s) | unknownDef();
data DefName = varName(str n) | unknownName();
data Def = def(DefName defName, DefValue defVal, loc defAt);

public rel[DefName, DefValue] getDefs(Expr e) {
	switch(e) {
		case assign(var(name(name(s))), av) : {
			if (scalar(sv) := av && encapsed(_) !:= sv) {
				return { < varName(s), scalarDef(sv) > };
			} else {
				return { < varName(s), unknownDef() > };
			}
		}

		case refAssign(var(name(name(s))), av) : {
			if (scalar(sv) := av && encapsed(_) !:= sv) {
				return { < varName(s), scalarDef(sv) > };
			} else {
				return { < varName(s), unknownDef() > };
			}
		}

		case assignWOp(var(name(name(s))), av, _) : {
			if (scalar(sv) := av && encapsed(_) !:= sv) {
				return { < varName(s), scalarDef(sv) > };
			} else {
				return { < varName(s), unknownDef() > };
			}
		}

		default : {
			return { };
		}
	}
}

public rel[DefName, DefValue, Lab] getDefs(CFGNode n) {
	switch(n) {
		case exprNode(Expr e, Lab l) : {
			return { <x,v,l> | <x,v> <- getDefs(e) };
		}
		
		case foreachAssignKey(Expr expr, Lab l) : {
			if (var(name(name(s))) := expr) {
				return { < varName(s), unknownDef(), l > };
			}
		}
		
		case foreachAssignValue(Expr expr, Lab l) : {
			if (var(name(name(s))) := expr) {
				return { < varName(s), unknownDef(), l > };
			}
		}

		case basicBlock(nl) : {
			return { *getDefs(ni) | ni <- nl };
		}
		
		case actualProvided(str paramName, bool refAssign) : {
			return { < varname(paramName), unknownDef(), l > };
		}
		
		case actualNotProvided(str paramName, Expr expr, bool refAssign) : {
			if (scalar(sv) := expr && encapsed(_) !:= sv) {
				return { < varname(paramName), scalarDef(sv), l > };
			} else {
				return { < varname(paramName), unknownDef(), l > };
			}
		}

		default : {
			return { };
		}
	}
}

public rel[DefName, DefValue, Lab] getDefs(CFG cfg) {
	return { *getDefs(n) | n <- cfg.nodes };
}

public set[Def] extractDefs(CFG cfg) {
	
}