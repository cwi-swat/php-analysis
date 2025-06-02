@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::metrics::CC

import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;

import List;

private set[Op] choiceOps = { booleanAnd(), booleanOr(), logicalAnd(), logicalOr(), logicalXor() };

public int exprChoiceCount(Expr e) = size([b | /b:binaryOperation(_,_,bop) := e, bop in choiceOps ]);

public int computeCC(list[Stmt] body) {
	int cc = 1; // The base path through the body
	
	whileLoops = [ w | /w:\while(_,_) := body ];
	for (w <- whileLoops) {
		cc += (1 + exprChoiceCount(w.cond));
	}
	
	forLoops = [ f | /f:\for(_,_,_,_) := body ];
	for (f <- forLoops) {
		cc += (1 + ( 0 | it + ecc | ecc <- [ exprChoiceCount(fc) | fc <- f.conds ]));
	}
	
	doLoops = [ d | /d:do(_,_) := body ];
	for (d <- doLoops) {
		cc += ( 1 + exprChoiceCount(d.cond) );
	}
	
	foreachLoops = [ f | /f:foreach(_,_,_,_,_) := body ];
	for (_ <- foreachLoops) {
		cc += 1;
	}
	
	// Find all conditionals
	ifs = [ i | /i:\if(_,_,_,_) := body ];
	for (i <- ifs) {
		cc += (1 + exprChoiceCount(i.cond));
		for (ei <- i.elseIfs) {
			cc += (1 + exprChoiceCount(ei.cond));
		}
	}
	
	ternarys = [ t | /t:ternary(_,_,_) := body ];
	for (t <- ternarys) {
		cc += (exprChoiceCount(t.cond));
		if (t.ifBranch is someExpr) {
			cc += 1;
		}
	}
	
	// Find all cases
	caseCount = size([ c | /c:\case(_,_) := body ]);
	
	// Find all catch blocks, we assume finally is part of the default path
	catchCount = size([ c | /c:\catch(_,_,_) := body ]);
	
	// The number of break and continue statements (note, we assume each induces an extra path; newer
	// versions of PHP require the break level to be a numeric literal, but in older versions this isn't
	// necessarily the case, although we didn't find any where arbitrary expressions were used)
	breakCount = size([ b | /b:\break(_) := body ]);
	continueCount = size([ c | /c:\continue(_) := body ]);
	
	// The number of throw statements
	throwCount = size([ t | /t:\throw(_) := body ]);
	
	cc = cc + caseCount + catchCount + breakCount + continueCount + throwCount;
	
	// Add up all the returns, minus 1 -- we assume we should have at least 1 if we have any at all
	returnCount = size([ r | /r:\return(_) := body]);
	if (returnCount > 1) {
		cc = cc + (returnCount - 1);
	}
	
	return cc;
}