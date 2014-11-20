@license{

  Copyright (c) 2009-2014 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::cfg::LabelState

import lang::php::ast::AbstractSyntax;
import lang::php::analysis::cfg::CFG;
import lang::php::analysis::cfg::Label;

import List;

@doc{The labeling state keeps track of information needed during the labeling and edge computation operations.}
data LabelState 
	= ls(int counter) 
	| ls(int counter, CFGNode entryNode, CFGNode exitNode, set[CFGNode] nodes, list[Lab] breakLabels, list[Lab] continueLabels, map[Lab,Lab] headerNodes, map[Lab,Lab] footerNodes, map[str,Lab] gotoNodes, map[str,Lab] catchHandlers)
	;

@doc{Initialize the label state}	
public LabelState newLabelState() = ls(0);

@doc{Expand the label state to include entry and exit information.}
public LabelState addEntryAndExit(LabelState lstate, CFGNode entryNode, CFGNode exitNode) {
	return ls(lstate.counter, entryNode, exitNode, { entryNode, exitNode }, [ ], [ ], ( ), ( ), ( ), ( ));
}

@doc{Throw away the entry and exit information, leaving just the counter.}
public LabelState shrink(LabelState lstate) {
	return ls(lstate.counter);
}

@doc{Get the labels of all the break targets}
public list[Lab] getBreakLabels(LabelState lstate) = lstate.breakLabels;

@doc{Get the nth break target (for, e.g., break 5)}
public Lab getBreakLabel(int n, LabelState lstate) = lstate.breakLabels[n-1]; 

@doc{Check to see if the given break target is available; it may not be if this code is included and breaks into surrounding code.}
public bool hasBreakLabel(int n, LabelState lstate) = size(lstate.breakLabels) <= n && size(lstate.breakLabels) > 0;

@doc{Push a new break label onto the stack}
public LabelState pushBreakLabel(Lab l, LabelState lstate) {
	lstate.breakLabels = push(l,lstate.breakLabels);
	return lstate;
} 

@doc{Pop a break label off the stack}
public LabelState popBreakLabel(LabelState lstate) {
	lstate.breakLabels = tail(lstate.breakLabels);
	return lstate;
}

@doc{Get the labels of all the continue targets}
public list[Lab] getContinueLabels(LabelState lstate) = lstate.continueLabels;

@doc{Get the nth continue target (for, e.g., continue 5)}
public Lab getContinueLabel(int n, LabelState lstate) = lstate.continueLabels[n-1]; 

@doc{Check to see if the given continue target is available; it may not be if this code is included and continues into surrounding code.}
public bool hasContinueLabel(int n, LabelState lstate) = size(lstate.continueLabels) <= n && size(lstate.continueLabels) > 0;

@doc{Push a new continue label onto the stack}
public LabelState pushContinueLabel(Lab l, LabelState lstate) {
	lstate.continueLabels = push(l,lstate.continueLabels);
	return lstate;
} 

@doc{Pop a continue label off the stack}
public LabelState popContinueLabel(LabelState lstate) {
	lstate.continueLabels = tail(lstate.continueLabels);
	return lstate;
}
 
 @doc{Get the current exit node}
public CFGNode getExitNode(LabelState lstate) = lstate.exitNode;

@doc{Get the label of the current exit node}
public Lab getExitNodeLabel(LabelState lstate) = lstate.exitNode@lab;

@doc{Label the statements and expressions in a script.}
public tuple[Script,LabelState] labelScript(Script script, LabelState lstate) {
	Lab incLabel() { 
		lstate.counter += 1; 
		return lab(lstate.counter); 
	}
	
	labeledScript = bottom-up visit(script) {
		case Stmt s => s[@lab = incLabel()]
		case Expr e => e[@lab = incLabel()]
	};
	
	return < labeledScript, lstate >;
}
