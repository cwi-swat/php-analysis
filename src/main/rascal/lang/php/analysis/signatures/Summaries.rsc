@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::signatures::Summaries

import ValueIO;
import lang::php::config::Config;

private loc summariesDir = baseLoc() + "serialized/summaries";

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

data Summary(loc from=|unknown:///|)
	= functionSummary(loc name, list[SummaryParam] params, bool returnsRef, str returnType, bool mayAlterGlobals, set[str] throwsTypes)
	| methodSummary(loc name, set[str] modifiers, list[SummaryParam] params, bool returnsRef, str returnType, bool mayAlterGlobals, set[str] throwsTypes)
	| constructorSummary(loc name, set[str] modifiers, list[SummaryParam] params, bool mayAlterGlobals, set[str] throwsTypes)
	| constantSummary(loc name, str constType)
	| classSummary(loc name, set[str] extends, set[str] implements)
	| fieldSummary(loc name, str fieldType, set[str] modifiers, str initializer)
	| invalidSummary(loc name, str reason)
	| emptySummary(loc name, loc path)
	;

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
