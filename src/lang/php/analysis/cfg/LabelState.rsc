@license{

  Copyright (c) 2009-2011 CWI
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

// The labeling state keeps track of information needed during
// the labeling and edge computation operations.
data LabelState 
	= ls(int counter) 
	| ls(int counter, CFGNode entryNode, CFGNode exitNode, set[CFGNode] nodes, list[Lab] breakLabels, list[Lab] continueLabels);
	
public LabelState newLabelState() = ls(0);

public LabelState addEntryAndExit(LabelState lstate, CFGNode entryNode, CFGNode exitNode) {
	return ls(lstate.counter, entryNode, exitNode, { entryNode, exitNode }, [ ], [ ]);
}
public LabelState shrink(LabelState lstate) {
	return ls(lstate.counter);
}

public list[Lab] getBreakLabels(LabelState lstate) = lstate.breakLabels;

public Lab getBreakLabel(int n, LabelState lstate) = lstate.breakLabels[n-1]; 

public bool hasBreakLabel(int n, LabelState lstate) = size(lstate.breakLabels) <= n;

public LabelState pushBreakLabel(Lab l, LabelState lstate) {
	lstate.breakLabels = push(l,lstate.breakLabels);
	return lstate;
} 

public LabelState popBreakLabel(LabelState lstate) {
	lstate.breakLabels = tail(lstate.breakLabels);
	return lstate;
}

public list[Lab] getContinueLabels(LabelState lstate) = lstate.continueLabels;

public Lab getContinueLabel(int n, LabelState lstate) = lstate.continueLabels[n-1]; 

public bool hasContinueLabel(int n, LabelState lstate) = size(lstate.continueLabels) <= n;

public LabelState pushContinueLabel(Lab l, LabelState lstate) {
	lstate.continueLabels = push(l,lstate.continueLabels);
	return lstate;
} 

public LabelState popContinueLabel(LabelState lstate) {
	lstate.continueLabels = tail(lstate.continueLabels);
	return lstate;
}
 
public CFGNode getExitNode(LabelState lstate) = lstate.exitNode;

public Lab getExitNodeLabel(LabelState lstate) = lstate.exitNode@lab;

// Label the statements and expressions in a script.
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

