module lang::php::analysis::includes::InlineIncludes

import lang::php::ast::AbstractSyntax;
import lang::php::util::System;
import String;
import Node;
import IO;
import List;

// Add this as an additional statement constructor, which gets slotted
// in when we remove statements (such as declarations for classes, which
// are hoisted to the top level)
//
// TODO: Remove this; we should write this at the level of the IR we
// are developing...
data Stmt = removedStmt();
data Expr = scriptFragment(list[Stmt] body);

public Script inlineScript(Script s, System sys, loc baseLoc) {
	list[Stmt] functionDefs = [ ];
	list[Stmt] classDefs = [ ];
	list[Stmt] interfaceDefs = [ ];
	list[Stmt] traitDefs = [ ];
					
	Script inlined = s;
	solve(inlined) {
		inlined = visit(inlined) {
			case i:include(scalar(string(str ipath)),itype) : {
				pathAsLoc = (startsWith(ipath, baseLoc.path)) ? (|file:///|+ipath) : (baseLoc+ipath);
				if (pathAsLoc in sys) {
					Script toInline = sys[pathAsLoc];
					
					// pull all the functions, classes, traits, and interfaces up to the top level
					pruned = bottom-up visit(toInline) {
						case f:functionDef(_,_,_,_) : {
							functionDefs += f;
							insert(removedStmt());
						}
						case c:classDef(_) : {
							classDefs += c;
							insert(removedStmt());
						}
						case t:traitDef(_) : {
							traitDefs += t;
							insert(removedStmt());
						}
						case i:interfaceDef(_) : {
							interfaceDefs += i;
							insert(removedStmt());
						}
						case [* a,removedStmt(),* b] => [ai | ai <- a, ai !:= removedStmt()] + [bi | bi <- b, bi !:= removedStmt()]
					}
					
					insert(scriptFragment(pruned.body)[@at=i@at]);
				} else {
					println("WARNING: Include path <pathAsLoc> is not a valid file in the system");
				}
			}
		}
	}
		
	inlined.body += (functionDefs + classDefs + interfaceDefs + traitDefs);
	
	return inlined;
}