module lang::php::m3::Containment

extend lang::php::m3::Core;

@doc { recursively fill containment }
public M3 fillContainment(M3 m3, Script script) {
	loc currNs = globalNamespace;
	
	for (stmt <- script.body)
		m3 = fillContainment(m3, stmt, script, currNs);
	
   	return m3;
}

public M3 fillContainment(M3 m3, Stmt statement, node parent, loc currNs) {
	switch(statement) {
		case ns:namespace(_,body): { 
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, ns, ns@decl);
		}
		
		case ns:namespaceHeader(_): {
			// set the current namespace to this namespace.
			currNs = ns@decl;
			fail; // continue the visit
		}
	
		// class/trait/interface/function set the parent node	
		case classDef(c:class(_,_,_,_,body)): {
			m3@containment += { <currNs, c@decl> };
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, c, currNs);
		}
		
		case interfaceDef(i:interface(_,_,body)): {
			m3@containment += { <currNs, i@decl> };
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, i, currNs);
		}
		
		case traitDef(t:trait(_,body)): {
			m3@containment += { <currNs, t@decl> };
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, t, currNs);
		}
		
		case f:function(_,_,params,body): { 
			m3@containment += { <currNs, f@decl> };
			
			for (p <- params)
				m3@containment += { <f@decl, p@decl> };
				
			for (stmt <- body) 
				m3 = fillContainment(m3, stmt, f, currNs);
		}
	
		// rest of the statements do not change the parent element
		
		// break and continue: needed for php < 5.4:
		// php > 5.4: Removed the ability to pass in variables (e.g., $num = 2; break $num;) as the numerical argument.
		case \break(optionExpr): {
			m3 = fillContainment(m3, optionExpr, parent, currNs);
		}
		
		case \continue(optionExpr): {
			m3 = fillContainment(m3, optionExpr, parent, currNs);
		}
		
		case const(consts): {
			for (const <- consts) 
				m3 = addVarDecl(m3, const, parent, currNs);
		}
		
		case declare(_,body): {
			for (stmt <- body) 
				m3 = fillContainment(m3, stmt, parent, currNs);
		}
		
		case do(cond, body): {
			m3 = fillContainment(m3, cond, parent, currNs);
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent, currNs);
		}
		
		case \while(cond, body): {
			m3 = fillContainment(m3, cond, parent, currNs);
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent, currNs);
		}
		
		case \for(inits, conds, exprs, body): {
			for (init <- inits)
				m3 = fillContainment(m3, init, parent, currNs);
			for (cond <- conds)
				m3 = fillContainment(m3, cond, parent, currNs);
			for (expr <- exprs)
				m3 = fillContainment(m3, expr, parent, currNs);
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent, currNs);
		}
		
		case foreach(expr, keyvar, _, asVar, body): {
			m3 = fillContainment(m3, expr, parent, currNs);
			m3 = fillContainment(m3, keyvar, parent, currNs);
			m3 = fillContainment(m3, cond, parent, currNs);
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent, currNs);
		}
		
		case \switch(cond, cases): {
			m3 = fillContainment(m3, cond, parent, currNs);
			
			for (case_ <- cases) {
				m3 = fillContainment(m3, case_.cond, parent, currNs);
				
				for (stmt <- case_.body)
					m3 = fillContainment(m3, stmt, parent, currNs);
			}
		}
		
		case \if(expr, body, elseIfs, elseClause): {
			m3 = fillContainment(m3, expr, parent, currNs);
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent, currNs);
				
			for (elseIf(cond, body) <- elseIfs) {
				m3 = fillContainment(m3, cond, parent, currNs);
				
				for (stmt <- body) 
					m3 = fillContainment(m3, stmt, parent, currNs);
			}
			
			m3 = fillContainment(m3, elseClause, parent, currNs);
		}
		
		case echo(exprs): {
			for (expr <- exprs)
				m3 = fillContainment(m3, expr, parent, currNs);
		}
		
		// global (not implemented)
		
		case \return(optionExpr): {
			m3 = fillContainment(m3, optionExpr, parent, currNs);
		}
				
		case static(vars): {
			for (var <- vars) {
				m3 = addVarDecl(m3, var, parent, currNs);
				m3 = fillContainment(m3, var.defaultValue, parent, currNs);
			}
		}
				
		case tryCatch(body, catches): {
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent, currNs);
		
			for (catch_ <- catches) {
				for (stmt <- catch_.body)
					m3 = fillContainment(m3, stmt, parent, currNs);
			}
		}
		
		case tryCatchFinally(body, catches, finallyBody): {
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent, currNs);
		
			for (catch_ <- catches) {
				for (stmt <- catch_.body) {
					m3 = fillContainment(m3, stmt, parent, currNs);
				}
			}
				
			for (stmt <- finallyBody)
				m3 = fillContainment(m3, stmt, parent, currNs);
		}
		
		case \throw(expr): {
			m3 = fillContainment(m3, expr, parent, currNs);
		}	
		
		case exprstmt(expr): {
			m3 = fillContainment(m3, expr, parent, currNs);
		}
		
		case block(body): {
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent, currNs);
		}
	}
	return m3;
}

public M3 fillContainment(M3 m3, OptionExpr optionExpr, node parent, loc currNs) {
	switch(optionExpr) {
		case someExpr(expr): {
			m3 = fillContainment(m3, expr, parent, currNs);
		}
	}	
	
	return m3;
}

public M3 fillContainment(M3 m3, OptionElse optionElse, node parent, loc currNs) {
	switch(optionElse) {
		case someElse(\else(body)): {
			for (stmt <- body) {
				m3 = fillContainment(m3, stmt, parent, currNs);
			}
		}
	}	
	
	return m3;
}

public M3 fillContainment(M3 m3, ClassItem ci, node parent, loc currNs) {
	top-down-break visit (ci) {
		case property(_,ps): {
			for (p <- ps)
				m3@containment += { <parent@decl, p@decl> };
		}
		
		case constCI(cs): {
			for (c <- cs)
				m3@containment += { <parent@decl, c@decl> };
		}
		
		case m:method(_,_,_,params,body): {
			m3@containment += { <parent@decl, m@decl> };
			
			for (p <- params) 
				m3@containment += { <m@decl, p@decl> };
				
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, m, currNs);
		}
	}
	
	return m3;
}

public M3 fillContainment(M3 m3, Expr e, node parent, loc currNs) {
	top-down visit (e) {
		case v:var(_): {
			if ( (v@decl)? ) {
				m3 = addVarDecl(m3, v, parent, currNs);
			}
		}
	}
	
	return m3;
}

public M3 addVarDecl(M3 m3, node n, node parent, loc currNs) {
	// sanity check
	assert getName(parent) in { "script", "namespace", "function", "class", "method", "interface", "trait" } : "Illegal parent node";
	
	switch (parent) {
		case Script::script(_): {
			// use current namespace
			m3@containment += { <currNs, n@decl> };
		}
			
		default: {
			m3@containment += { <parent@decl, n@decl> };
		}
	}
	
	return m3;
}