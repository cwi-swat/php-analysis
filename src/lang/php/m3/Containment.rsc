module lang::php::m3::Containment

extend lang::php::m3::Core;


@doc { recursively fill containment }
public M3 fillContainment(M3 m3, Script script) {
	for (stmt <- script.body) 
		m3 = fillContainment(m3, stmt, script);
		
   	return m3;
}

public M3 fillContainment(M3 m3, Stmt statement, node parent) {
	switch(statement) {
		case ns:namespace(_,body): { 
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, ns);
		}
		
		// class/trait/interface/function set the parent node	
		case classDef(c:class(_,_,_,_,body)): {
			loc ns = getNamespace(m3@containment, parent@decl);
			m3@containment += { <ns, c@decl> };
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, c);
		}
		
		case interfaceDef(i:interface(_,_,body)): {
			loc ns = getNamespace(m3@containment, parent@decl);
			m3@containment += { <ns, i@decl> };
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, i);
		}
		
		case traitDef(t:trait(_,body)): {
			loc ns = getNamespace(m3@containment, parent@decl);
			m3@containment += { <ns, t@decl> };
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, t);
		}
		
		case f:function(_,_,params,body): { 
			loc ns = getNamespace(m3@containment, parent@decl);
			m3@containment += { <ns, f@decl> };
			
			for (p <- params)
				m3@containment += { <f@decl, p@decl> };
				
			for (stmt <- body) 
				m3 = fillContainment(m3, stmt, f);
		}
	
		// rest of the statements do not change the parent element
		
		// break and continue: needed for php < 5.4:
		// php > 5.4: Removed the ability to pass in variables (e.g., $num = 2; break $num;) as the numerical argument.
		case \break(optionExpr): {
			m3 = fillContainment(m3, optionExpr, parent);
		}
		
		case \continue(optionExpr): {
			m3 = fillContainment(m3, optionExpr, parent);
		}
		
		case const(consts): {
			for (const <- consts) 
				m3 = addVarDecl(m3, const, parent);
		}
		
		case declare(_,body): {
			for (stmt <- body) 
				m3 = fillContainment(m3, stmt, parent);
		}
		
		case do(cond, body): {
			m3 = fillContainment(m3, cond, parent);
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent);
		}
		
		case \while(cond, body): {
			m3 = fillContainment(m3, cond, parent);
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent);
		}
		
		case \for(inits, conds, exprs, body): {
			for (init <- inits)
				m3 = fillContainment(m3, init, parent);
			for (cond <- conds)
				m3 = fillContainment(m3, cond, parent);
			for (expr <- exprs)
				m3 = fillContainment(m3, expr, parent);
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent);
		}
		
		case foreach(expr, keyvar, _, asVar, body): {
			m3 = fillContainment(m3, expr, parent);
			m3 = fillContainment(m3, keyvar, parent);
			m3 = fillContainment(m3, cond, parent);
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent);
		}
		
		case \switch(cond, cases): {
			m3 = fillContainment(m3, cond, parent);
			
			for (case_ <- cases) {
				m3 = fillContainment(m3, case_.cond, parent);
				
				for (stmt <- case_.body)
					m3 = fillContainment(m3, stmt, parent);
			}
		}
		
		case \if(expr, body, elseIfs, elseClause): {
			m3 = fillContainment(m3, expr, parent);
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent);
				
			for (elseIf(cond, body) <- elseIfs) {
				m3 = fillContainment(m3, cond, parent);
				
				for (stmt <- body) 
					m3 = fillContainment(m3, stmt, parent);
			}
			
			m3 = fillContainment(m3, elseClause, parent);
		}
		
		case echo(exprs): {
			for (expr <- exprs)
				m3 = fillContainment(m3, expr, parent);
		}
		
		// global (not implemented)
		
		case \return(optionExpr): {
			m3 = fillContainment(m3, optionExpr, parent);
		}
				
		case static(vars): {
			for (var <- vars) {
				m3 = addVarDecl(m3, var, parent);
				m3 = fillContainment(m3, var.defaultValue, parent);
			}
		}
				
		case tryCatch(body, catches): {
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent);
		
			for (catch_ <- catches) {
				for (stmt <- catch_.body)
					m3 = fillContainment(m3, stmt, parent);
			}
		}
		
		case tryCatchFinally(body, catches, finallyBody): {
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent);
		
			for (catch_ <- catches) {
				for (stmt <- catch_.body) {
					m3 = fillContainment(m3, stmt, parent);
				}
			}
				
			for (stmt <- finallyBody)
				m3 = fillContainment(m3, stmt, parent);
		}
		
		case \throw(expr): {
			m3 = fillContainment(m3, expr, parent);
		}	
		
		case exprstmt(expr): {
			m3 = fillContainment(m3, expr, parent);
		}
		
		case block(body): {
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent);
		}
	}
	return m3;
}

public M3 fillContainment(M3 m3, OptionExpr optionExpr, node parent) {
	switch(optionExpr) {
		case someExpr(expr): {
			m3 = fillContainment(m3, expr, parent);
		}
	}	
	
	return m3;
}

public M3 fillContainment(M3 m3, OptionElse optionElse, node parent) {
	switch(optionElse) {
		case someElse(\else(body)): {
			for (stmt <- body) {
				m3 = fillContainment(m3, stmt, parent);
			}
		}
	}	
	
	return m3;
}

public M3 fillContainment(M3 m3, ClassItem ci, node parent) {
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
				m3 = fillContainment(m3, stmt, m);
		}
	}
	
	return m3;
}

public M3 fillContainment(M3 m3, Expr e, node parent) {
	top-down visit (e) {
		case v:var(_): {
			if ( (v@decl)? ) {
				m3 = addVarDecl(m3, v, parent);
			}
		}
	}
	
	return m3;
}

public M3 addVarDecl(M3 m3, node n, node parent) {
	// sanity check
	assert getName(parent) in { "script", "namespace", "function", "class", "method", "interface", "trait" } : "Illegal parent node";
	
	m3@containment += { <parent@decl, n@decl> };
	
	return m3;
}

public loc getNamespace(rel[loc from, loc to] containment, loc decl) {
	containment = invert(containment);
	solve(decl) {
		if (!isNamespace(decl)) {
			decl = getOneFrom(containment[decl]);	
		}
	}
	return decl;
}