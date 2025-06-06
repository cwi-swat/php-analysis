@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module tests::lang::php::m3::Core

import lang::php::m3::Core;
import lang::php::m3::FillM3;
import lang::php::m3::Containment;
import lang::php::m3::Uses;
import lang::php::config::Config;
import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;

import IO;
import List;
import Map;
import Node;
import Relation;
import Set;

import ValueIO;

// test PHP Schemes -- incomplete list
public test bool testIsNamespace() = isNamespace(|php+namespace:///|);
public test bool testIsClass()     = isClass(|php+class:///|);
public test bool testIsMethod()    = isMethod(|php+method:///|);
public test bool testIsTrait()     = isTrait(|php+trait:///|);
public test bool testIsParameter() = isParameter(|php+functionParam:///|) && isParameter(|php+methodParam:///|);
public test bool testIsFunction()  = isFunction(|php+function:///|);
public test bool testIsVariable()  = isVariable(|php+globalVar:///|) && isVariable(|php+functionVar:///|) && isVariable(|php+methodVar:///|);
public test bool testIsField()     = isField(|php+field:///|);
public test bool testIsInterface() = isInterface(|php+interface:///|);


public loc testFolder = analysisLoc() + "src/tests/resources/m3";

// test the creation of m3s
public test bool testFillM3() {
	throw ("method should not be used");
	M3Collection m3s = getM3s();
	map[str,int] counter = ();
	for (f <- testFolder.ls) {
		if (f.extension == "m3") {
			loc phpFile = getPhpFileNameFromM3File(f);
			M3 actual = m3s[phpFile];
			M3 expected = readTextValueFile(#M3, f);
			
			actualAnnos = getAnnotations(actual);
			expectedAnnos = getAnnotations(expected);
			
			// check all annotations set in expected
			for(key <- expectedAnnos) {
				counter[key] = key in counter ? counter[key] + 1 : 1; // count the number of tests
				if (expectedAnnos[key] != actualAnnos[key]) {
					printFailedTest(phpFile, key, "<expectedAnnos[key]>", "<actualAnnos[key]>");
					return false;
				}
			}
		}
	}
	println("Total number of tests executed: <counter>");
	return true;
}

public test bool testGetM3ForDirectory() 
{
	M3 m3 =	getM3ForDirectory(testFolder);
	
	return m3ContainsExpectedResults(m3);
}

public bool m3ContainsExpectedResults(M3 m3) 
{
	map[str,int] counter = ();
	for (f <- testFolder.ls) {
		if (f.extension == "m3") {
			M3 expected = readTextValueFile(#M3, f);
			
			expectedAnnos = getAnnotations(expected);
			
			// check all annotations set in expected
			for(key <- expectedAnnos) {
				counter[key] = key in counter ? counter[key] + 1 : 1; // count the number of tests
				if (!assertAnnotation(key, m3, "<expectedAnnos[key]>")) {
					return false;
				}	
			}
		}
	}
	println("Total number of tests executed: <counter>");
	return true;
}

private bool assertAnnotation(str key, M3 m3, str expected)
{
	actualAnnos = getAnnotations(m3);
    if (key in ["uses", "declarations"]) {
   		if (!assertAnnotationLocLoc(expected, actualAnnos[key])) return false;
	} else if (key in ["modifiers"]) {
   		if (!assertAnnotationLocModifier(expected, actualAnnos[key])) return false;
	} else {
		throw("Unsupported type of annotations. Please implement: \'<key>\'");	
	}
	
	return true;
}

private bool assertAnnotationLocLoc(str expectedRaw, rel[loc,loc] actual)
{
	rel[loc,loc] expected = readTextValueString(#rel[loc,loc], "<expectedRaw>");
	unImplemented = expected - actual;
	if (!isEmpty(unImplemented)) {
		iprintln(unImplemented);	
		return false;	
	}
	return true;
}

private bool assertAnnotationLocModifier(str expectedRaw, rel[loc,Modifier] actual)
{
   	rel[loc,Modifier] expected = readTextValueString(#rel[loc,Modifier], "<expectedRaw>");
	unImplemented = expected - actual;
	if (!isEmpty(unImplemented)) {
		iprintln(unImplemented);	
		return false;	
	}
	return true;
}

private M3Collection getM3s() = getM3CollectionForSystem(getSystem(testFolder), testFolder);

private loc getPhpFileNameFromM3File(loc f) = testFolder+"<f.file[0..-3]>.php";

private void printFailedTest(loc phpFile, str annotation, str expected, str actual) {
    println("Test failed for file: `<phpFile.file>`, on `<annotation>` (test stopped)");
    println("Not in Expected/actual:");
    if (annotation in ["uses", "declarations"]) {
        rel[loc,loc] e = readTextValueString(#rel[loc,loc], expected);
        rel[loc,loc] a = readTextValueString(#rel[loc,loc], actual);
        println(sort(e-a));
        println(sort(a-e));
    } else if (annotation in ["modifiers"]) {
        rel[loc,Modifier] e = readTextValueString(#rel[loc,Modifier], expected);
        rel[loc,Modifier] a = readTextValueString(#rel[loc,Modifier], actual);
        println(sort(e-a));
        println(sort(a-e));
    } else {
        throw ("implement node <annotation>");
    }
}