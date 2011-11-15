@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::MemoryNode

import lang::php::analysis::Inheritance;

//
// Name paths, used to identify the path in the code to a given name (including names
// such as x[], or x->f).
//
data NamePart = root() | global() | class(str className) | method(str methodName) | field(str fieldName) | var(str varName) | arrayContents() ;
alias NamePath = list[NamePart];

//
// Abstract memory items. For objects, we track the instantiated class and the allocation site,
// which we use as a shorthand to keep track of unique objects. This is part of the flow
// insensitivity of this analysis -- all objects allocated at a given allocation site are considered
// to be the same object, which could lead to bigger points-to sets.
//
data MemItem = scalarVal() | arrayVal() | objectVal(str className, int allocationSite) | sameAs(NamePath np);

//
// Memory nodes represent a memory cell, including children
//
alias MemoryNode = int;

@doc{Create a new root memory node}
@javaClass{lang.php.analysis.internal.MemoryModel}
public java MemoryNode makeRootNode(FieldsRel fr);

@doc{Add a set of items into the memory, given the complete path and the set of items.}
@javaClass{lang.php.analysis.internal.MemoryModel}
public java void addItems(MemoryNode memoryNode, NamePath npath, set[MemItem] items);

@doc{Add a single item into the memory, given the complete path.}
public void addItems(MemoryNode memoryNode, NamePath npath, MemItem item) {
	addItems(memoryNode, npath, { item });
}

@doc{Add a single item into the memory, given the path and child at that path.}
public void addItems(MemoryNode memoryNode, NamePath npath, NamePart np, MemItem item) {
	addItems(memoryNode, npath + np, { item });
}

@doc{Add a set of items into the memory, given the path and child at that path.}
public void addItems(MemoryNode memoryNode, NamePath npath, NamePart np, set[MemItem] items) {
	addItems(memoryNode, npath + np, items);
}

@doc{Given the complete path to a set of items, return that set.}
@javaClass{lang.php.analysis.internal.MemoryModel}
public java set[MemItem] getItems(MemoryNode memoryNode, NamePath npath, type[&T] result);

public set[MemItem] getItems(MemoryNode memoryNode, NamePath npath) = getItems(memoryNode, npath, #MemItem);

@doc{Check to see if a node exists at the given path.}
@javaClass{lang.php.analysis.internal.MemoryModel}
public java bool hasNode(MemoryNode memoryNode, NamePath npath);

@doc{Check to see if a node exists at the given path.}
@javaClass{lang.php.analysis.internal.MemoryModel}
public java bool mergeNodes(MemoryNode memoryNode, NamePath fromTop, NamePath toTop);

@doc{Check to see if a node exists at the given path.}
@javaClass{lang.php.analysis.internal.MemoryModel}
public java void deleteRootNode(MemoryNode memoryNode);

@doc{Collapse the memory node into a relation.}
@javaClass{lang.php.analysis.internal.MemoryModel}
public java rel[NamePath,MemItem] collapseToRelation(MemoryNode memoryNode, NamePath npath, type[&T] left, type[&T] right);

public rel[NamePath,MemItem] collapseToRelation(MemoryNode memoryNode) = collapseToRelation(memoryNode, [], #NamePart, #MemItem);

public void insertFromRelation(MemoryNode memoryNode, rel[NamePath,MemItem] source) {
	for (np <- source<0>) addItems(memoryNode, source[np]);
}

//@doc{Check to see if there are any cycles in the memory node.}
//@javaClass{lang.php.analysis.internal.MemoryModel}
//public java bool checkForCycles(MemoryNode memoryNode);
//
//@doc{Find the deepest path in the memory node.}
//@javaClass{lang.php.analysis.internal.MemoryModel}
//public java list[value] findDeepestPath(MemoryNode memoryNode);

@doc{Get the number of reachable nodes.}
@javaClass{lang.php.analysis.internal.MemoryModel}
public java int getNodeCount(MemoryNode memoryNode);

@doc{Get the number of objects.}
@javaClass{lang.php.analysis.internal.MemoryModel}
public java int getObjectCount(MemoryNode memoryNode);

@doc{Get the number of object children.}
@javaClass{lang.php.analysis.internal.MemoryModel}
public java int getObjectChildCount(MemoryNode memoryNode);

@doc{Get the number of items in the item sets stored in the memory.}
@javaClass{lang.php.analysis.internal.MemoryModel}
public java int getItemCount(MemoryNode memoryNode);
