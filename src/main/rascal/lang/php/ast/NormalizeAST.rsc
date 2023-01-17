@license{
  Copyright (c) 2009-2013 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::ast::NormalizeAST

import lang::php::ast::AbstractSyntax;
import List;
import IO;
import Node;
import String;

data Expr = blockedVar(NameOrExpr varName);

// NOTE: This has a type error. Commenting out for now, with potential
// future removal, since this back-ports a new syntax into a prior syntax.
// public Script oldListAssignments(Script s) { 
// 	solve(s) { 
// 		s = visit(s) { 
// 			case assign(listExpr(L),E) => listAssign(L,E) 
// 		}
// 	} 
// 	return s;
// }

public Script oldNamespaces(Script s) {
	solve(s) {
		s = visit(s) {
			case namespaceHeader(Name nn) => namespace(someName(nn), [])
		}
	}
	return s;
}

public Stmt createIf(ElseIf e:elseIf(Expr cond, list[Stmt] body), OptionElse oe) {
	return \if(cond, body, [], oe)[at=e.at];
}

public Script normalizeIf(Script s) {
	// NOTE: We copy the locations over. This isn't completely valid, since we are
	// then using locations for items that don't actually appear anywhere in the
	// source, but this at least helps to tie these back to the original code.
	solve(s) {
		s = bottom-up visit(s) {
			case i:\if(cond,body,elseifs,els) : {
				if (size(elseifs) > 0) {
					workingElse = els;
					for (e <- reverse(elseifs)) {
						newIf = createIf(e, workingElse);
						workingElse = someElse(\else([newIf])[at=newIf.at]);
					}
					insert(\if(cond,body,[],workingElse)[at=i.at]);
				}
			}
		}
	}
	return s;
}

public Script flattenBlocks(Script s) {
	solve(s) {
		s = bottom-up visit(s) {
			case [list[Stmt]] [*Stmt xs,block(list[Stmt] ys),*Stmt zs] => [*xs,*ys,*zs]
		}
	}
	return s;
}

public Script discardEmpties(Script s) {
	solve(s) {
		s = bottom-up visit(s) {
			case [list[Stmt]] [*Stmt xs,emptyStmt(),*Stmt zs] : {
				list[Stmt] r = [*xs,*zs];
				insert(r);
			}
		}
	}
	return s;
}

public Script useBuiltins(Script s) {
	solve(s) {
		s = bottom-up visit(s) {
			case call(name(name("isset")),params) => isSet([e | actualParameter(e,_,_) <- params])
			
			case call(name(name("exit")),[]) => exit(noExpr(), true)
			
			case call(name(name("exit")),[actualParameter(e,_,_)]) => exit(someExpr(e), true)
			
			case call(name(name("die")),[]) => exit(noExpr(), false)
			
			case call(name(name("die")),[actualParameter(e,_,_)]) => exit(someExpr(e), false)

			case call(name(name("print")),[actualParameter(e,_,_)]) => Expr::print(e)
			
			case exprstmt(call(name(name("unset")),params)) => unset([e | actualParameter(e,_,_) <- params])

			case call(name(name("empty")),[actualParameter(e,_,_)]) => empty(e)

			case call(name(name("eval")),[actualParameter(e,_,_)]) => eval(e)
		}
	}
	return s;
}

public Script discardHTML(Script s) {
	solve(s) {
		s = bottom-up visit(s) {
			case inlineHTML(_) => inlineHTML("")
		}
	}
	return s;	
}

public Script mergeHTML(Script s) {
	solve(s) {
		s = bottom-up visit(s) {
			case list[Stmt] _: [*Stmt xs,inlineHTML(i),inlineHTML(j),*Stmt ys] => [*xs,inlineHTML(i+j),*ys]
		}
	}
	return s;
}

public Script discardScalarContents(Script s) {
	solve(s) {
		s = bottom-up visit(s) {
			case scalar(string(_)) => scalar(string(""))
			case scalar(float(_)) => scalar(float(0.0))
		}
	}
	return s;
}

public Script normalizeArrayAccesses(Script s) {
	solve(s) {
		s = bottom-up visit(s) {
			case staticPropertyFetch(pc,expr(fetchArrayDim(var(vn),ad))) =>
				fetchArrayDim(staticPropertyFetch(pc,vn),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(var(vn),ad))) =>
				 fetchArrayDim(propertyFetch(e,vn),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(var(vn),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(var(vn),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad2),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad3),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad3),ad2),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad4),ad3),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad4),ad3),ad2),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad5),ad4),ad3),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad5),ad4),ad3),ad2),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad6),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad6),ad5),ad4),ad3),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad6),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad6),ad5),ad4),ad3),ad2),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad7),ad6),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad7),ad6),ad5),ad4),ad3),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad7),ad6),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad7),ad6),ad5),ad4),ad3),ad2),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad9),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad9),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad9),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad9),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad10),ad9),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad10),ad9),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(var(vn),ad10),ad9),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad10),ad9),ad8),ad7),ad6),ad5),ad4),ad3),ad2),ad)
		}
	}
	return s;
}

public Script replaceBlockedVars(Script s) {
	solve(s) {
		s = visit(s) {
			case blockedVar(v) => var(v)
		}
	}
	return s;
}

public Script switchNamespaceSeparators(Script s) {
	//solve(s) {
	//	s = visit(s) {
	//		case name(str ns) => name(replaceAll(ns,"::","\\")) when contains(ns,"::")
	//	}
	//}
	return s;
}

// TODO: Fix this, but need to check to see current representation of use from PDT
//public Script setDefaultUseAlias(Script s) {
//	solve(s) {
//		s = visit(s) {
//			case use(name(str un), noName()) => use(name(un),someName(name(last(split("/",un)))))
//		}
//	}
//	return s;
//}

public Script normalizeEncapsedStrings(Script s) {
	solve(s) {
		s = visit(s) {
			case scalar(encapsed([scalar(string(str ic))])) => scalar(string(ic))
		}
	}
	return s;
}

public Script discardModifiers(Script s) {
	set[Modifier] emptySM = { };
	
	solve(s) {
		s = visit(s) {
			case set[Modifier] _ => emptySM 
		}
	}
	return s;
}

// dirty setAnnotations and getAnnotations to keep the annotations of the origional node on the new node.
public Script addPublicModifierWhenNotProvided(Script s) {
	set[Modifier] publicModifier = { \public() };
	
	solve(s) {
		s = visit(s) {
			case origNode:property(set[Modifier] mfs, prop) => 
				setAnnotations( property(mfs + publicModifier, prop), getAnnotations(origNode))
			when \public() notin mfs && \private() notin mfs && \protected() notin mfs
				
			case origNode:method(str mname, set[Modifier] mfs, byRef, params, body, rtype) => 
				setAnnotations( method(mname, mfs + publicModifier, byRef, params, body, rtype), getAnnotations(origNode))
			when \public() notin mfs && \private() notin mfs && \protected() notin mfs
		}
	}
	return s;
}

public Script discardAnnotations(Script s) = delAnnotationsRec(s);
