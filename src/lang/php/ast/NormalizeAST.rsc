module lang::php::ast::NormalizeAST

import lang::php::ast::AbstractSyntax;
import List;

public Stmt createIf(elseIf(Expr cond, list[Stmt] body), OptionElse oe) {
	return \if(cond, body, [], oe);
}

public Script normalizeIf(Script s) {
	solve(s) {
		s = bottom-up visit(s) {
			case \if(cond,body,elseifs,els) : {
				if (size(elseifs) > 0) {
					workingElse = els;
					for (e <- reverse(elseifs)) {
						newIf = createIf(e, workingElse);
						workingElse = someElse(\else([newIf]));
					}
					insert(\if(cond,body,[],workingElse));
				}
			}
		}
	}
	return s;
}

public Script flattenBlocks(Script s) {
	solve(s) {
		s = bottom-up visit(s) {
			case [*xs,block(list[Stmt] ys),*zs] => [*xs,*ys,*zs]
		}
	}
	return s;
}

public Script discardEmpties(Script s) {
	solve(s) {
		s = bottom-up visit(s) {
			case [*xs,emptyStmt(),*zs] : {
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
			case call(name(name("isset")),params) => isSet([e | actualParameter(e,_) <- params])
			
			case call(name(name("exit")),[]) => exit(noExpr())
			
			case call(name(name("exit")),[actualParameter(e,_)]) => exit(someExpr(e))
			
			case call(name(name("die")),[]) => exit(noExpr())
			
			case call(name(name("die")),[actualParameter(e,_)]) => exit(someExpr(e))

			case call(name(name("print")),[actualParameter(e,_)]) => print(e)
			
			case exprstmt(call(name(name("unset")),params)) => unset([e | actualParameter(e,_) <- params])

			case call(name(name("empty")),[actualParameter(e,_)]) => empty(e)
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
			case [*xs,inlineHTML(i),inlineHTML(j),*ys] => [*xs,inlineHTML(i+j),*ys]
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
			case staticPropertyFetch(pc,expr(fetchArrayDim(v:var(vn),ad))) =>
				 fetchArrayDim(staticPropertyFetch(pc,vn),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(v:var(vn),ad))) =>
				 fetchArrayDim(propertyFetch(e,vn),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(v:var(vn),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(v:var(vn),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad2),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(v:var(vn),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad3),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(v:var(vn),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad3),ad2),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(v:var(vn),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad4),ad3),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(v:var(vn),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad4),ad3),ad2),ad)

			case staticPropertyFetch(pc,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(v:var(vn),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(staticPropertyFetch(pc,vn),ad5),ad4),ad3),ad2),ad)
				 
			case propertyFetch(e,expr(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(v:var(vn),ad5),ad4),ad3),ad2),ad))) =>
				 fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(fetchArrayDim(propertyFetch(e,vn),ad5),ad4),ad3),ad2),ad)
		}
	}
	return s;
}