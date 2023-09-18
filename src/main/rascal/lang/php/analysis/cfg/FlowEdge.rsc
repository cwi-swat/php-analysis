@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Apalachean State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
	| backEdge(Lab from, Lab to)
	| jumpEdge(Lab from, Lab to)
	| conditionTrueFlowEdge(Lab from, Lab to, Lab header, Expr why)
	| conditionTrueFlowEdge(Lab from, Lab to, Lab header, Expr why, list[Expr] whyNots)
	| conditionTrueFlowEdge(Lab from, Lab to, Lab header, list[Expr] whys)
	| conditionTrueFlowEdge(Lab from, Lab to, Lab header, list[Expr] whys, list[Expr] whyNots)
	| conditionTrueBackEdge(Lab from, Lab to, Lab header, Expr why)
	| conditionFalseFlowEdge(Lab from, Lab to, Lab header, Expr whyNot)
	| conditionFalseFlowEdge(Lab from, Lab to, Lab header, list[Expr] whyNots)
	| iteratorEmptyFlowEdge(Lab from, Lab to, Lab header, Expr arr)
	| iteratorNotEmptyFlowEdge(Lab from, Lab to, Lab header, Expr arr)
	| escapingBreakEdge(Lab from, Lab to, OptionExpr breakAmount)
	| escapingContinueEdge(Lab from, Lab to, OptionExpr continueAmount)
	| escapingGotoEdge(Lab from, Lab to, str gotoLabel)
	;
	
alias FlowEdges = set[FlowEdge];

public str printFlowEdgeLabel(flowEdge(Lab from, Lab to)) = "Flow";
public str printFlowEdgeLabel(backEdge(Lab from, Lab to)) = "Back";
public str printFlowEdgeLabel(jumpEdge(Lab from, Lab to)) = "Jump";
public str printFlowEdgeLabel(conditionTrueFlowEdge(Lab from, Lab to, Lab header, Expr why)) = "True: <pp(why)>";
public str printFlowEdgeLabel(conditionTrueFlowEdge(Lab from, Lab to, Lab header, Expr why, list[Expr] whyNots)) = "True: <pp(why)>";
public str printFlowEdgeLabel(conditionTrueFlowEdge(Lab from, Lab to, Lab header, list[Expr] whys)) = "True: <intercalate(",",[pp(w)|w<-whys])>";
public str printFlowEdgeLabel(conditionTrueFlowEdge(Lab from, Lab to, Lab header, list[Expr] whys, list[Expr] whyNots)) = "True: <intercalate(",",[pp(w)|w<-whys])>";
public str printFlowEdgeLabel(conditionTrueBackEdge(Lab from, Lab to, Lab header, Expr why)) = "True: <pp(why)>";
public str printFlowEdgeLabel(conditionFalseFlowEdge(Lab from, Lab to, Lab header, Expr whyNot)) = "False: <pp(whyNot)>";
public str printFlowEdgeLabel(conditionFalseFlowEdge(Lab from, Lab to, Lab header, list[Expr] whyNots)) = "False: <intercalate(",",[pp(w)|w<-whyNots])>";
public str printFlowEdgeLabel(iteratorEmptyFlowEdge(Lab from, Lab to, Lab header, Expr arr)) = "Empty";
public str printFlowEdgeLabel(iteratorNotEmptyFlowEdge(Lab from, Lab to, Lab header, Expr arr)) = "Not Empty";
public str printFlowEdgeLabel(escapingBreakEdge(Lab from, Lab to, OptionExpr breakAmount)) = "break";
public str printFlowEdgeLabel(escapingContinueEdge(Lab from, Lab to, OptionExpr continueAmount)) = "continue";
public str printFlowEdgeLabel(escapingGotoEdge(Lab from, Lab to, str gotoLabel)) = "goto";
