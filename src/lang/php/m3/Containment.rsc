module lang::php::m3::Containment

extend lang::php::m3::Core;

@doc { recursively fill containment }
public M3 fillContainment(M3 m3, Script script) {
	println("---------------------------------------------------------");
	println("visit script: <script>");
	loc currNs = globalNamespace;
	
	for (stmt <- script.body)
		m3 = fillContainment(m3, stmt, script, currNs);
	
   	return m3;
}

public M3 fillContainment(M3 m3, Stmt statement, node parent, loc currNs) {
	println("visit stmt: <statement>");
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
			println("class: <currNs> \>\> <c@decl>");
			m3@containment += { <currNs, c@decl> };
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, c, currNs);
		}
		case interfaceDef(i:interface(_,_,body)): {
			println("interface: <currNs> \>\> <i@decl>");
			m3@containment += { <currNs, i@decl> };
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, i, currNs);
		}
		case traitDef(t:trait(_,body)): {
			println("trait: <currNs> \>\> <t@decl>");
			m3@containment += { <currNs, t@decl> };
			
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, t, currNs);
		}
		case f:function(_,_,params,body): { 
			println("function: <currNs> \>\> <f@decl>");
			m3@containment += { <currNs, f@decl> };
			
			for (p <- params) {
				println("function param: <f@decl> \>\> <p@decl>");
				m3@containment += { <f@decl, p@decl> };
			}
				
			for (stmt <- body) {
				m3 = fillContainment(m3, stmt, f, currNs);
			}
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
			for (const <- consts) {
				if ( (parent@decl)? ) {
					m3@containment += { <parent@decl, const@decl> };
				} else {
					m3@containment += { <currNs, const@decl> };
				}
			}
		
		}
		
		case declare(_,body): {
			for (stmt <- body) {
				m3 = fillContainment(m3, stmt, parent, currNs);
			}
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
			
			for (stmt <- body) {
				m3 = fillContainment(m3, stmt, parent, currNs);
			}
				
			for (elseIf(cond, body) <- elseIfs) {
				m3 = fillContainment(m3, cond, parent, currNs);
				for (stmt <- body) {
					m3 = fillContainment(m3, stmt, parent, currNs);
				}
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
				if ( (parent@decl)? ) {
					m3@containment += { <parent@decl, var@decl> };
				} else {
					m3@containment += { <currNs, var@decl> };
				}	
				m3 = fillContainment(m3, var.defaultValue, parent, currNs);
				println("ssdf");
			}
		}
				
		case tryCatch(body, catches): {
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, parent, currNs);
		
			for (catch_ <- catches) {
				for (stmt <- catch_.body) {
					m3 = fillContainment(m3, stmt, parent, currNs);
				}
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
		
		case \throw(expr):
			m3 = fillContainment(m3, expr, parent, currNs);
		
		
		case exprstmt(expr): {
			// find the function, class, or namespace scope.
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
	println("visit optionExpr: <optionExpr>");
	switch(optionExpr) {
		case someExpr(expr): {
			m3 = fillContainment(m3, expr, parent, currNs);
		}
	}	
	
	return m3;
}

public M3 fillContainment(M3 m3, OptionElse optionElse, node parent, loc currNs) {
	println("visit optionElse: <optionElse>");
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
	println("visit classItem: <ci>");
	top-down-break visit (ci) {
		case property(_,ps): {
			for (p <- ps) {	
				println("class property: <parent@decl> \>\> <p@decl>");
				m3@containment += { <parent@decl, p@decl> };
			}
		}
		case constCI(cs): {
			for (c <- cs) {
				println("class constant: <parent@decl> \>\> <c@decl>");
				m3@containment += { <parent@decl, c@decl> };
			}
		}
		case m:method(_,_,_,params,body): {
			println("class method: <parent@decl> \>\> <m@decl>");
			m3@containment += { <parent@decl, m@decl> };
			
			for (p <- params) {
				println("class method param: <m@decl> \>\> <p@decl>");
				m3@containment += { <m@decl, p@decl> };
			}
				
			for (stmt <- body)
				m3 = fillContainment(m3, stmt, m, currNs);
		}
	}
	
	return m3;
}

public M3 fillContainment(M3 m3, Expr e, node parent, loc currNs) {
	println("visit Expr: <e>");
	top-down visit (e) {
		case v:var(_): {
			if ( (v@decl)? ) {
				if ( (parent@decl)? ) {
					println("variable, parent decl: <parent@decl> \>\> <v@decl>");
					m3@containment += { <parent@decl, v@decl> };
				} else {
					println("variable, no parent decl: <currNs> \>\> <v@decl>");
					m3@containment += { <currNs, v@decl> };
				}
			}
		}
	}
	
	return m3;
}
