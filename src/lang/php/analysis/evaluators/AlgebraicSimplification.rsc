@license{

  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::evaluators::AlgebraicSimplification

import lang::php::ast::AbstractSyntax;
import Set;
import List;
import String;
import Exception;

@doc{Perform algebraic simplification over operations formed just with scalars. We could also
     simplify expressions like 0 * e, but would risk discarding any side effects caused by e.}
public Script algebraicSimplification(Script scr) {
	scr = bottom-up visit(scr) {
		case e:binaryOperation(scalar(string(s1)),scalar(string(s2)),concat()) =>
			 scalar(string(s1+s2))[@at=e@at]

		case e:binaryOperation(scalar(integer(i1)),scalar(integer(i2)),plus()) =>
			 scalar(integer(i1+i2))[@at=e@at]
			 
		case e:binaryOperation(scalar(integer(i1)),scalar(integer(i2)),minus()) =>
			 scalar(integer(i1-i2))[@at=e@at]
			 
		case e:binaryOperation(scalar(integer(i1)),scalar(integer(i2)),mul()) =>
			 scalar(integer(i1*i2))[@at=e@at]
			 
		case e:binaryOperation(scalar(integer(i1)),scalar(integer(i2)),\mod()) =>
			 scalar(integer(i1%i2))[@at=e@at]
			 
		case e:binaryOperation(scalar(integer(i1)),scalar(integer(i2)),div()) =>
			 scalar(integer(i1/i2))[@at=e@at]
	}
	return scr;
}