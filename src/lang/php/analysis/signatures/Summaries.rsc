@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::signatures::Summaries

import ValueIO;
import lang::php::analysis::NamePaths;

data SummaryParam
	= standardParam(str paramType, str paramName)
	| standardRefParam(str paramType, str paramName)
	| optionalParam(str paramType, str paramName)
	| optionalRefParam(str paramType, str paramName)
	| standardVarParam(str paramType)
	| standardVarRefParam(str paramType)
	| optionalVarParam(str paramType)
	| optionalVarRefParam(str paramType)
	| voidParam()
	;

data Summary 
	= functionSummary(NamePath name, list[SummaryParam] params, bool returnsRef, str returnType, bool mayAlterGlobals, set[str] throwsTypes)
	| methodSummary(NamePath name, set[str] modifiers, list[SummaryParam] params, bool returnsRef, str returnType, bool mayAlterGlobals, set[str] throwsTypes)
	| constructorSummary(NamePath name, set[str] modifiers, list[SummaryParam] params, bool mayAlterGlobals, set[str] throwsTypes)
	| constantSummary(NamePath name, str constType)
	| classSummary(NamePath name, set[str] extends, set[str] implements)
	| fieldSummary(NamePath name, str fieldType, set[str] modifiers, str initializer)
	| invalidSummary(NamePath name, str reason)
	| emptySummary(NamePath name, loc path)
	;
	
public anno loc Summary@from;

data NamePart = libraryConstants();

public set[Summary] loadFunctionSummaries() {
	return readBinaryValueFile(#set[Summary], |rascal://src/lang/php/analysis/signatures/phpFunctions.bin|);
}

public void saveFunctionSummaries(set[Summary] summaries) {
	writeBinaryValueFile(|rascal://src/lang/php/analysis/signatures/phpFunctions.bin|, summaries);
}

public set[Summary] loadConstantSummaries() {
	return readBinaryValueFile(#set[Summary], |rascal://src/lang/php/analysis/signatures/phpConstants.bin|);
}

public void saveConstantSummaries(set[Summary] summaries) {
	writeBinaryValueFile(|rascal://src/lang/php/analysis/signatures/phpConstants.bin|, summaries);
}

public set[Summary] loadClassSummaries() {
	return readBinaryValueFile(#set[Summary], |rascal://src/lang/php/analysis/signatures/phpClasses.bin|);
}

public void saveClassSummaries(set[Summary] summaries) {
	writeBinaryValueFile(|rascal://src/lang/php/analysis/signatures/phpClasses.bin|, summaries);
}

public set[Summary] loadMethodSummaries() {
	return readBinaryValueFile(#set[Summary], |rascal://src/lang/php/analysis/signatures/phpMethods.bin|);
}

public void saveMethodSummaries(set[Summary] summaries) {
	writeBinaryValueFile(|rascal://src/lang/php/analysis/signatures/phpMethods.bin|, summaries);
}

public set[Summary] loadSummaries() {
	functionSummaries = loadFunctionSummaries();
	constantSummaries = loadConstantSummaries();
	classSummaries = loadClassSummaries();
	methodSummaries = loadMethodSummaries();
	return functionSummaries + constantSummaries + classSummaries + methodSummaries;
}
