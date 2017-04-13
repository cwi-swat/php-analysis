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
import lang::php::util::Config;
import lang::php::analysis::NamePaths;

private loc summariesDir = baseLoc + "serialized/summaries";

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
	= functionSummary(loc name, list[SummaryParam] params, bool returnsRef, str returnType, bool mayAlterGlobals, set[str] throwsTypes)
	| methodSummary(loc name, set[str] modifiers, list[SummaryParam] params, bool returnsRef, str returnType, bool mayAlterGlobals, set[str] throwsTypes)
	| constructorSummary(loc name, set[str] modifiers, list[SummaryParam] params, bool mayAlterGlobals, set[str] throwsTypes)
	| constantSummary(loc name, str constType)
	| classSummary(loc name, set[str] extends, set[str] implements)
	| fieldSummary(loc name, str fieldType, set[str] modifiers, str initializer)
	| invalidSummary(loc name, str reason)
	| emptySummary(loc name, loc path)
	;
	
public anno loc Summary@from;

public set[Summary] loadFunctionSummaries() {
	return readBinaryValueFile(#set[Summary], summariesDir + "phpFunctions.bin");
}

public void saveFunctionSummaries(set[Summary] summaries) {
	writeBinaryValueFile(summariesDir + "phpFunctions.bin", summaries);
}

public set[Summary] loadConstantSummaries() {
	return readBinaryValueFile(#set[Summary], summariesDir + "phpConstants.bin");
}

public void saveConstantSummaries(set[Summary] summaries) {
	writeBinaryValueFile(summariesDir + "phpConstants.bin", summaries);
}

public set[Summary] loadClassSummaries() {
	return readBinaryValueFile(#set[Summary], summariesDir + "phpClasses.bin");
}

public void saveClassSummaries(set[Summary] summaries) {
	writeBinaryValueFile(summariesDir + "phpClasses.bin", summaries);
}

public set[Summary] loadMethodSummaries() {
	return readBinaryValueFile(#set[Summary], summariesDir + "phpMethods.bin");
}

public void saveMethodSummaries(set[Summary] summaries) {
	writeBinaryValueFile(summariesDir + "phpMethods.bin", summaries);
}

public set[Summary] loadSummaries() {
	functionSummaries = loadFunctionSummaries();
	constantSummaries = loadConstantSummaries();
	classSummaries = loadClassSummaries();
	methodSummaries = loadMethodSummaries();
	return functionSummaries + constantSummaries + classSummaries + methodSummaries;
}
