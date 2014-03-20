@license{

  Copyright (c) 2009-2014 CWI
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
	| escapingBreakEdge(Lab from, Lab to, OptionExpr breakAmount)
	| escapingContinueEdge(Lab from, Lab to, OptionExpr continueAmount)
	;
	
alias FlowEdges = set[FlowEdge];

public str printFlowEdgeLabel(flowEdge(Lab from, Lab to)) = "";
public str printFlowEdgeLabel(conditionTrueFlowEdge(Lab from, Lab to, Expr why)) = "True: <pp(why)>";
public str printFlowEdgeLabel(conditionTrueFlowEdge(Lab from, Lab to, Expr why, list[Expr] whyNots)) = "True: <pp(why)>";
public str printFlowEdgeLabel(conditionTrueFlowEdge(Lab from, Lab to, list[Expr] whys)) = "True: <intercalate(",",[pp(w)|w<-whys])>";
public str printFlowEdgeLabel(conditionTrueFlowEdge(Lab from, Lab to, list[Expr] whys, list[Expr] whyNots)) = "True: <intercalate(",",[pp(w)|w<-whys])>";
public str printFlowEdgeLabel(conditionFalseFlowEdge(Lab from, Lab to, Expr whyNot)) = "False: <pp(whyNot)>";
public str printFlowEdgeLabel(conditionFalseFlowEdge(Lab from, Lab to, list[Expr] whyNots)) = "False: <intercalate(",",[pp(w)|w<-whyNots])>";
public str printFlowEdgeLabel(iteratorEmptyFlowEdge(Lab from, Lab to, Expr arr)) = "Empty";
public str printFlowEdgeLabel(iteratorNotEmptyFlowEdge(Lab from, Lab to, Expr arr)) = "Not Empty";
public str printFlowEdgeLabel(escapingBreakEdge(Lab from, Lab to, OptionExpr breakAmount)) = "";
public str printFlowEdgeLabel(escapingContinueEdge(Lab from, Lab to, OptionExpr continueAmount)) = "";
