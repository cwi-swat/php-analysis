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

public Scalar concatScalars(Scalar sc1:string(str s1), Scalar sc2:string(str s2)) = string(s1+s2);
public Scalar concatScalars(Scalar sc1:string(str s1), Scalar sc2:integer(int i1)) = string("<s1><i1>");
public Scalar concatScalars(Scalar sc1:integer(int i1), Scalar sc2:string(str s2)) = string("<i1><s2>");
public Scalar concatScalars(Scalar sc1:integer(int i1), Scalar sc2:integer(int i2)) = string("<i1><i2>");
public Scalar concatScalars(Scalar sc1:string(str s1), Scalar sc2:float(real r1)) = string("<s1><r1>");
public Scalar concatScalars(Scalar sc1:float(real r1), Scalar sc2:string(str s2)) = string("<r1><s2>");
public Scalar concatScalars(Scalar sc1:float(real r1), Scalar sc2:float(real r2)) = string("<r1><r2>");

@doc{Perform algebraic simplification over operations formed just with scalars. We could also
     simplify expressions like 0 * e, but would risk discarding any side effects caused by e.}
public Script algebraicSimplification(Script scr) {
	return bottom-up visit(scr) {
		case e:binaryOperation(scalar(sc1),scalar(sc2),concat()) : {
			if (string(_) := sc1 || integer(_) := sc1 || float(_) := sc1) {
				if (string(_) := sc2 || integer(_) := sc2 || float(_) := sc2) {
			 		insert(scalar(concatScalars(sc1,sc2))[@at=e@at]);
			 	}
			}
		}

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
			 
		// If we have an encapsed string that is now fully resolved -- i.e., only
		// uses literals -- then collapse it into a single string.
		case s:scalar(encapsed(el)) : {
			scalarParts = [ e | e <- el, scalar(sp) := e, string(_) := sp || integer(_) := sp || float(_) := sp ];
			if (size(el) == size(scalarParts)) {
				res = ( string("") | concatScalars(it,sc) | scalar(sc) <- el );
				insert(scalar(res[@at=head(el)@at])[@at=s@at]);
			}
		}
	}
}

public Expr algebraicSimplification(Expr expr) {
	return bottom-up visit(expr) {
		case e:binaryOperation(scalar(sc1),scalar(sc2),concat()) : {
			if (string(_) := sc1 || integer(_) := sc1 || float(_) := sc1) {
				if (string(_) := sc2 || integer(_) := sc2 || float(_) := sc2) {
			 		insert(scalar(concatScalars(sc1,sc2))[@at=e@at]);
			 	}
			}
		}

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
			 
		// If we have an encapsed string that is now fully resolved -- i.e., only
		// uses literals -- then collapse it into a single string.
		case s:scalar(encapsed(el)) : {
			scalarParts = [ e | e <- el, scalar(sp) := e, string(_) := sp || integer(_) := sp || float(_) := sp ];
			if (size(el) == size(scalarParts)) {
				res = ( string("") | concatScalars(it,sc) | scalar(sc) <- el );
				insert(scalar(res[@at=head(el)@at])[@at=s@at]);
			}
		}
	}
}