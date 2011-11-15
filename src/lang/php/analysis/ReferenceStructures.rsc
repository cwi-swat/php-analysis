@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::ReferenceStructures

import lang::php::analysis::MemoryNode;

alias SetValuedMap = int;

@doc{Create a new set-valued map}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java SetValuedMap makeSetValuedMap();

@doc{Add an item to the map}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java void addValue(SetValuedMap svm, value key, value v);

@doc{Add a set of items to the map}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java void addValues(SetValuedMap svm, value key, set[value] vs);

@doc{Retrieve the set of available keys}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java set[NamePath] getKeys(SetValuedMap svm, type[&T] domain);
public set[NamePath] getKeys(SetValuedMap svm) = getKeys(svm, #NamePart);

@doc{Retrieve the set of items available at the given key}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java set[NamePath] getValues(SetValuedMap svm, type[&T] range, value key);
public set[NamePath] getValues(SetValuedMap svm, value key) = getValues(svm, #NamePart, key);

@doc{Retrieve the set of items available at the given key}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java rel[NamePath, NamePath] asRelation(SetValuedMap svm, type[&T] domain, type[&U] range);
public rel[NamePath, NamePath] asRelation(SetValuedMap svm) = asRelation(svm, #NamePart, #NamePart);

public SetValuedMap createFromRelation(rel[NamePath, NamePath] r) {
	SetValuedMap svm = makeSetValuedMap();
	for (np <- r<0>) addValues(svm, np, r[np]);
	return svm;
}

@doc{Delete the indicated set-valued map}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java void deleteSetValuedMap(SetValuedMap svm);

@doc{Get the number of keys in the map.}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java int getKeyCount(SetValuedMap svm);

@doc{Get the number of values in the map.}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java int getValueCount(SetValuedMap svm);

@doc{Remove the values associated with a key.}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java bool removeValuesForKey(SetValuedMap svm, value key);

@doc{Remove the specific value associated with the given key.}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java bool removeValueForKey(SetValuedMap svm, value key, value v);

@doc{Return a map showing, for each key, the number of items}
@javaClass{lang.php.analysis.internal.ReferenceStructures}
public java map[NamePath,int] getKeyCountMap(SetValuedMap svm, type[&T] domain);

public map[NamePath,int] getKeyCountMap(SetValuedMap svm) = getKeyCountMap(svm, #NamePart);
