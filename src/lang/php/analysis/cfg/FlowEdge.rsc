@license{

  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::cfg::FlowEdge

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::Label;
import lang::php::pp::PrettyPrinter;
import List;

// A flow edge records the flow from one label to the next.
data FlowEdge 
	= flowEdge(Lab from, Lab to) 
	| conditionTrueFlowEdge(Lab from, Lab to, Expr why)
	| conditionTrueFlowEdge(Lab from, Lab to, Expr why, list[Expr] whyNots)
	| conditionTrueFlowEdge(Lab from, Lab to, list[Expr] whys)
	| conditionTrueFlowEdge(Lab from, Lab to, list[Expr] whys, list[Expr] whyNots)
	| conditionFalseFlowEdge(Lab from, Lab to, Expr whyNot)
	| conditionFalseFlowEdge(Lab from, Lab to, list[Expr] whyNots)
	| iteratorEmptyFlowEdge(Lab from, Lab to, Expr arr)
	| iteratorNotEmptyFlowEdge(Lab from, Lab to, Expr arr)
	;
	
alias FlowEdges = set[FlowEdge];

public str printFlowEdgeLabel(FlowEdge fe) {
	switch(fe) {
		case flowEdge(_,_) : return "";
		case conditionTrueFlowEdge(_,_,Expr why) : 
			return "True: <pp(why)>";
		case conditionTrueFlowEdge(_,_,Expr why,_) : 
			return "True: <pp(why)>";
		case conditionTrueFlowEdge(_,_,list[Expr] whys) : 
			return "True: <intercalate(",",[pp(w)|w<-whys])>";
		case conditionTrueFlowEdge(_,_,list[Expr] whys,_) : 
			return "True: <intercalate(",",[pp(w)|w<-whys])>";
		case conditionFalseFlowEdge(_,_,Expr whyNot) : 
			return "False: <pp(whyNot)>";
		case conditionFalseFlowEdge(_,_,list[Expr] whyNots) : 
			return "False: <intercalate(",",[pp(w)|w<-whyNots])>";
			//return "False: <pp(intercalate(",",[pp(w)|w<-whyNots]))>";
		case iteratorEmptyFlowEdge(_,_,arr) : 
			return "Empty";
		case iteratorNotEmptyFlowEdge(_,_,arr) : 
			return "Not Empty";
	}
}