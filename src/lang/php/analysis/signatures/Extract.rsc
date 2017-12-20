@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::analysis::signatures::Extract

import IO;
import Node;
import Set;
import String;
import List;
import Map;
import lang::html::IO;
import lang::php::analysis::NamePaths;
import lang::php::analysis::signatures::Summaries;

private loc defaultStart = |http://www.php.net/manual/en/funcref.php|;
private loc dbVendorStart = |http://nl3.php.net/manual/en/refs.database.vendors.php|;

data PageType 
	= functionPage(str libraryName, str functionName)
	| constantPage(str libraryName)
	| classPage(str libraryName, str className)
	| methodPage(str libraryName, str className, str methodName)
	;
	
public map[PageType,loc] getLibraryPages() = getLibraryPages(defaultStart);

public map[PageType,loc] getDBLibraryPages() = getLibraryPages(dbVendorStart);

public map[PageType,loc] getAllLibraryPages() = getLibraryPages() + getDBLibraryPages();

public map[PageType,loc] getLibraryPages(loc startingLoc) {
	map[PageType,loc] pathPages = ( );
	
	// First, get back the root of the library documentation
	node srctxt = readHTMLFile(startingLoc);
	
	// Now, extract out the names of the "books", which are the starting points for
	// the descriptions of the various libraries
	set[node] books = { n | /node n <- srctxt, getName(n) == "a", "href" in getKeywordParameters(n), str s := getKeywordParameters(n)["href"], /book\./ := s  };
	
	int limiter = 0;
	
	// Now, go through each, getting the functions in each
	for (book <- books, str bookhref := getKeywordParameters(book)["href"]) {
	//for (book <- books, str bookhref := getKeywordParameters(book)["href"], limiter < 10, "a"(["text"(bn)]) := book, /Cairo/ := bn) {
		bookloc = startingLoc.parent + bookhref;
		booktxt = readHTMLFile(bookloc);
		bookname = "";
		if ("a"(["text"(bn),*_]) := book)
			bookname = bn;
		else
			throw "Error, cannot calculate name of book <book>";

		// Extract out locations of function pages
		set[node] funs = { n | /node n <- booktxt, getName(n) == "a", 
			"href" in getKeywordParameters(n), 
			str s := getKeywordParameters(n)["href"], 
			/function\./ := s, "a"(l) := n, 
			[_*,"img"(),_*] !:= l };
		pathPages += ( functionPage(bookname, funname) : startingLoc.parent + funhref | 
			fun:"a"(["text"(str funname)]) <- funs, 
			str funhref := getKeywordParameters(fun)["href"], 
			/function\.<funnamelink:.*>\.php/ := funhref );
		println("Added <size(funs)> function pages for book <bookname>");
		
		// Extract out locations of constants pages
		set[node] constants = { n | /node n <- booktxt, getName(n) == "a", 
			"href" in getKeywordParameters(n), 
			str s := getKeywordParameters(n)["href"], 
			/\.constants\./ := s, 
			"a"(l) := n, 
			[_*,"img"(),_*] !:= l };
		pathPages += ( constantPage(bookname) : startingLoc.parent + consthref | 
			const <- constants, 
			str consthref := getKeywordParameters(const)["href"] );
		println("Added <size(constants)> constants pages for book <bookname>");

		// Extract out the class pages; we need this info to find the method pages as well
		set[node] classes = { n | 
			/node n:"a"(l) <- booktxt, 
			"href" in getKeywordParameters(n), 
			str s := getKeywordParameters(n)["href"], 
			/class\./ := s, 
			[_*,"img"(),_*] !:= l };
		pathPages += ( classPage(bookname, classname) : startingLoc.parent + classhref | 
			class:"a"(["text"(str classname)]) <- classes, 
			str classhref := getKeywordParameters(class)["href"], 
			/class\.<classlinkname:.*>\.php/ := classhref);
		println("Added <size(classes)> class pages for book <bookname>");
		
		// For each class, extract out the method pages
		for (class:"a"(["text"(str cn)]) <- classes) {
			methodInfo = { < cn, mn, mp > |
				/node n:"a"(["text"(str mnfull)]) <- booktxt,
				/<cn>::<mn:.+>\s*/ := mnfull,
				"href" in getKeywordParameters(n),
				str mp := getKeywordParameters(n)["href"] };
			pathPages += ( methodPage(bookname, cn, mn) : startingLoc.parent + mp | < _, mn, mp> <- methodInfo );
			println("Added <size(methodInfo)> methods for class <cn>");
		}	
		
		limiter += 1;
	}
	
	return pathPages;
}

public set[Summary] extractFunctionSummary(str bookname, str functionName, loc functionLoc) {
	println("<bookname>: Extracting summaries for function <functionName> from path <functionLoc.path>");
	node ftxt = readHTMLFile(functionLoc);
	str httpishName = replaceAll(functionName,"_","-");
	set[node] matches = { n | /node n := ftxt, getName(n) == "div", "id" in getKeywordParameters(n), getKeywordParameters(n)["id"] == "function.<httpishName>" };
	if (size(matches) == 0) {
		httpishName = toLowerCase(httpishName);
		matches = { n | /node n := ftxt, getName(n) == "div", "id" in getKeywordParameters(n), getKeywordParameters(n)["id"] == "function.<httpishName>" };
	}
	set[Summary] summaries = { };
	for (match <- matches) {
		set[node] divTags = { n | /node n := match, "div" == getName(n), "class" in getKeywordParameters(n), str cn := getKeywordParameters(n)["class"], /methodsynopsis/ := cn };
		for ("div"(list[node] tagList) <- divTags) {
			bool foundRType = false;
			str rType = "";
			list[SummaryParam] params = [ ];
			bool addedSummary = false;
			int optionalDepth = 0;

			for (tagItem <- tagList) {
				// First, find the return type
				if (!foundRType) {
					if (rn:"span"(_) := tagItem, "class" in getKeywordParameters(rn), getKeywordParameters(rn)["class"] == "type") {
						set[str] rtypes = { s | /"text"(s) := rn };
						if (size(rtypes) != 1) {
							summaries += invalidSummary(functionPath(functionName,library=bookname), "Function <functionName> has <size(rtypes)> return types, 1 expected");
							break;
						}
						rType = getOneFrom(rtypes);
						foundRType = true;
						continue;
					}
				}
			
				if ("text"(s) := tagItem, /\[/ := s) optionalDepth += 1;
	
				if ("text"(s) := tagItem, /\]/ := s) optionalDepth -= 1;
				 	
				if (sn:"span"(slist) := tagItem, "class" in getKeywordParameters(sn), getKeywordParameters(sn)["class"] == "methodparam") {
					if (["text"("void")] := slist) {
						params += voidParam();
						break;
					}
					 
					set[str] ptypes = { s | /node n:"span"(_) := sn, "class" in getKeywordParameters(n), getKeywordParameters(n)["class"] == "type", /"text"(s) := n };
					if (size(ptypes) != 1) {
						summaries += invalidSummary(functionPath(functionName,library=bookname), "Function <functionName> has <size(ptypes)> parameter types for the same parameter, 1 expected");
						addedSummary = true;
						break;
					}
					str ptype = getOneFrom(ptypes);
					
					set[str] pnames = { s | /node n:"code"(_) := sn, "class" in getKeywordParameters(n), str cln := getKeywordParameters(n)["class"], /parameter/ := cln, /"text"(s) := n };
					if (size(pnames) != 1) {
						summaries += invalidSummary(functionPath(functionName,library=bookname), "Function <functionName> has <size(pnames)> parameter names for the same parameter, 1 expected");
						addedSummary = true;
						break;
					} 
					str pname = getOneFrom(pnames);
					
					if (size(pname) > 0 && pname[0] == "&") {
						pname = substring(pname,1);
						if (optionalDepth > 0) {
							if ("$..." == pname)
								params += optionalVarRefParam(ptype);
							else
								params += optionalRefParam(ptype, pname);
						} else {
							if ("$..." == pname)
								params += standardVarRefParam(ptype);
							else
								params += standardRefParam(ptype, pname);
						}
					} else {
						if (optionalDepth > 0) {
							if ("$..." == pname)
								params += optionalVarParam(ptype);
							else
								params += optionalParam(ptype, pname);
						} else {
							if ("$..." == pname)
								params += standardVarParam(ptype);
							else
								params += standardParam(ptype, pname);
						}					
					}
				}
			}			
			if (!addedSummary)
				summaries += functionSummary(functionPath(functionName,library=bookname), params, false, rType, false, {});
		}
	}
	
	if (size(summaries) == 0) {
		println("WARNING: No summaries extracted for function <functionName> at path <functionLoc.path>");
	}
	
	return summaries;
}

public set[Summary] extractConstantSummary(str bookname, loc constantLoc) {
	println("<bookname>: Extracting constants for library <bookname> from path <constantLoc.path>");
	set[Summary] summaries = { };
	set[str] alreadyFound = { };

	try {
		node ctxt = readHTMLFile(constantLoc);
		
		for (/str s(list[node] cl) := ctxt,
			 s in {"dt","td","span" }, 
		     ["strong"(["code"(["text"(str cn)])]),"text"(str t1),node sn:"span"(list[node] sl),"text"(str t2)] := cl,
		     contains(t1,"("), 
		     contains(t2,")"), 
		     "class" in getKeywordParameters(sn), 
		     getKeywordParameters(sn)["class"] == "type", 
		     ["a"(["text"(str tn)])] := sl ) {
		 
		 	summaries += constantSummary(constPath(cn,library=bookname), tn);
		 	alreadyFound += cn;   
		}
	
		for (/node n:"tr"(["td"(list[node] cl)]) := ctxt,
		     "id" in getKeywordParameters(n), 
		     str nId := getKeywordParameters(n)["id"],
		     /constant\./ := nId, 
		     ["strong"(["code"(["text"(str cn)])])] := cl,
		     cn notin alreadyFound ) {
		 
		 	summaries += constantSummary(constPath(cn,library=bookname), "");
		 	alreadyFound += cn;    
		}
	
		if (size(summaries) == 0) {
			println("WARNING: No summaries extracted for constants at path <constantLoc.path>");
		}
	} catch v : {
		println("Warning, could not extract constants from <bookname>: <v>");
	}
	return summaries;
}

public set[Summary] extractClassSummary(str bookname, str className, loc classLoc) {
	println("<bookname>: Extracting summaries for class <className> from path <classLoc.path>");
	node ctxt = readHTMLFile(classLoc);
	set[Summary] summaries = { };
	
	extendsSet = { cn | /node n:"span"([node m:"span"(["text"(str ext)]), _*, "a"(["text"(str cn)]), _*]) := ctxt,
		"class" in getKeywordParameters(n), getKeywordParameters(n)["class"] == "ooclass",
		"class" in getKeywordParameters(m), getKeywordParameters(m)["class"] == "modifier",
		/extends/ := ext };

	implementsSet = { cn | /node n:"span"(l) := ctxt,
		"class" in getKeywordParameters(n), getKeywordParameters(n)["class"] == "oointerface",
		[_*,node m:"span"(l2),_*] := l,
		"class" in getKeywordParameters(m), getKeywordParameters(m)["class"] == "interfacename",
		[_*, "a"(["text"(str cn)]),_*] := l2};

	set[str] foundFields = { };
	
	fieldsWModsWInit = { < fn , ft, init, mtxt > | /node n:"div"(l) := ctxt,
		"class" in getKeywordParameters(n), getKeywordParameters(n)["class"] == "fieldsynopsis",
		[_*,node m:"span"(l2),_*] := l,
		"class" in getKeywordParameters(m), getKeywordParameters(m)["class"] == "modifier",
		[_*,"text"(str mtxt),_*] := l2,
		[_*,node t:"span"(l3),_*] := l,
		"class" in getKeywordParameters(t), getKeywordParameters(t)["class"] == "type",
		/"text"(str ft) := l3,
		[_*,node i:"span"(l4),_*] := l,
		"class" in getKeywordParameters(i), getKeywordParameters(i)["class"] == "initializer",
		[_*,"text"(str initAll),_*] := l4,
		/=\s*<init:.+>\s*/ := initAll,
		/"var"(["text"(str fn)]) := l };

	foundFields += fieldsWModsWInit<0>;
	
	fieldsWMods = { < fn , ft, mtxt > | /node n:"div"(l) := ctxt,
		"class" in getKeywordParameters(n), getKeywordParameters(n)["class"] == "fieldsynopsis",
		[_*,node m:"span"(l2),_*] := l,
		"class" in getKeywordParameters(m), getKeywordParameters(m)["class"] == "modifier",
		[_*,"text"(str mtxt),_*] := l2,
		[_*,node t:"span"(l3),_*] := l,
		"class" in getKeywordParameters(t), getKeywordParameters(t)["class"] == "type",
		/"text"(str ft) := l3,
		/"var"(["text"(str fn)]) := l,
		fn notin foundFields };
		
	foundFields += fieldsWMods<0>;
	
	fieldsWInit = { < fn, ft, init > | /node n:"div"(l) := ctxt,
		"class" in getKeywordParameters(n), getKeywordParameters(n)["class"] == "fieldsynopsis",
		[_*,node t:"span"(l3),_*] := l,
		"class" in getKeywordParameters(t), getKeywordParameters(t)["class"] == "type",
		/"text"(str ft) := l3,
		[_*,node i:"span"(l4),_*] := l,
		"class" in getKeywordParameters(i), getKeywordParameters(i)["class"] == "initializer",
		[_*,"text"(str initAll),_*] := l4,
		/=\s*<init:.+>\s*/ := initAll,
		/"var"(["text"(str fn)]) := l,
		fn notin foundFields };

	foundFields += fieldsWInit<0>;
	
	fields = { < fn, ft > | /node n:"div"(l) := ctxt,
		"class" in getKeywordParameters(n), getKeywordParameters(n)["class"] == "fieldsynopsis",
		[_*,node t:"span"(l3),_*] := l,
		"class" in getKeywordParameters(t), getKeywordParameters(t)["class"] == "type",
		/"text"(str ft) := l3,
		/"var"(["text"(str fn)]) := l,
		fn notin foundFields };

	summaries = { fieldSummary(fieldPath(className, fn, library=bookname),ft,fieldsWMods[fn,ft],"") | <fn,ft,_> <- fieldsWMods };
	summaries += { fieldSummary(fieldPath(className, fn, library=bookname),ft,fieldsWModsWInit[fn,ft,fi],fi) | <fn,ft,fi,_> <- fieldsWModsWInit };
	summaries += { fieldSummary(fieldPath(className, fn, library=bookname),ft,{},"") | <fn,ft> <- fields };
	summaries += { fieldSummary(fieldPath(className, fn, library=bookname),ft,{},fi) | <fn,ft,fi> <- fieldsWInit };
	summaries += classSummary(classPath(className, library=bookname), extendsSet, implementsSet);

	if (size(summaries) == 0) {
		println("WARNING: No summaries extracted for class <className> at path <classLoc.path>");
		summaries += emptySummary([library(bookname),class(className)], classLoc);
	}

	return summaries;
	
}

public set[Summary] extractMethodSummary(str bookname, str className, str methodName, loc methodLoc) {
	println("<bookname>: Extracting summaries for method <className>::<methodName> from path <methodLoc.path>");
	node mtxt = readHTMLFile(methodLoc);
	str httpishName = "<toLowerCase(className)>.";
	set[Summary] summaries = { };
	bool ooMode = true;
	
	for (/node n:"div"(nbody) := mtxt, "id" in getKeywordParameters(n), str dId := getKeywordParameters(n)["id"], /<httpishName>/ := dId) {
		for (/node m:"div"(mbody) := nbody, "id" in getKeywordParameters(m), str mId := getKeywordParameters(m)["id"], /description/ := mId) {
			for (node k <- mbody) {
				if (/"text"(str ktxt) := k, /Procedural/ := ktxt) ooMode = false;
				if (/node ms:"div"(tagList) := k, "class" in getKeywordParameters(ms), str msClass := getKeywordParameters(ms)["class"], /methodsynopsis/ := msClass) {
					list[SummaryParam] params = [ ];
					int optionalDepth = 0;
					set[str] modifiers = { };
					set[str] rtypes = { };
					str methodName = "";
					bool paramProblems = false;
					
					for (tagItem <- tagList) {
						if (mn:"span"(["text"(str mtxt)]) := tagItem, "class" in getKeywordParameters(mn), getKeywordParameters(mn)["class"] == "modifier") {
							modifiers += mtxt;
						} else if (rn:"span"(_) := tagItem, "class" in getKeywordParameters(rn), getKeywordParameters(rn)["class"] == "type") {
							rtypes = { s | /"text"(s) := rn };
						} else if ("text"(s) := tagItem, /\[/ := s) {
							optionalDepth += 1;
						} else if ("text"(s) := tagItem, /\]/ := s) {
							optionalDepth -= 1;
						} else if (mn:"span"(["strong"(["text"(str mname)])]) := tagItem, "class" in getKeywordParameters(mn), getKeywordParameters(mn)["class"] == "methodname") {
							methodName = mname;
						} else if (sn:"span"(slist) := tagItem, "class" in getKeywordParameters(sn), getKeywordParameters(sn)["class"] == "methodparam") {
							if (["text"("void")] := slist) {
								params += voidParam();
								break;
							}
							 
							set[str] ptypes = { s | /node n:"span"(_) := sn, "class" in getKeywordParameters(n), getKeywordParameters(n)["class"] == "type", /"text"(s) := n };
							if (size(ptypes) != 1) {
								paramProblems = true;
								break;
							}
							str ptype = getOneFrom(ptypes);
							
							set[str] pnames = { s | /node n:"code"(_) := sn, "class" in getKeywordParameters(n), str cln := getKeywordParameters(n)["class"], /parameter/ := cln, /"text"(s) := n };
							if (size(pnames) != 1) {
								paramProblems = true;
								break;
							} 
							str pname = getOneFrom(pnames);
							
							if (size(pname) > 0 && pname[0] == "&") {
								pname = substring(pname,1);
								if (optionalDepth > 0)
									params += optionalRefParam(ptype, pname);
								else
									params += standardRefParam(ptype, pname);
							} else {
								if (optionalDepth > 0)
									params += optionalParam(ptype, pname);
								else
									params += standardParam(ptype, pname);					
							}
						}
					}
					
					if (ooMode && /<className>::<onlymn:.+>$/ := methodName)
						methodName = onlymn;
						
					loc mpath = ooMode ? methodPath(className,methodName,library=bookname) : functionPath(methodName,library=bookname);

					if ((size(rtypes) == 1 && !paramProblems) || "__construct" == methodName) {
						if (ooMode) {
							if ("__construct" == methodName)
								summaries += constructorSummary(mpath, modifiers, params, false, {});
							else
								summaries += methodSummary(mpath, modifiers, params, false, getOneFrom(rtypes), false, {});
						} else {
							summaries += functionSummary(mpath, params, false, getOneFrom(rtypes), false, {});
						}
					} else {
						if (size(rtypes) == 1)
							summaries += invalidSummary(mpath, "Encountered problems reading params");
						else											
							summaries += invalidSummary(mpath, "Expected 1 return type, found <size(rtypes)>");
					}			
				}		
			}			
		}
	}
	 
	if (size(summaries) == 0) {
		println("WARNING: No summaries extracted for method <methodName> in class <className> at path <methodLoc.path>");
	}

	return summaries;
}

public set[Summary] extractFunctionSummaries(map[PageType,loc] pagePaths) {	
	set[Summary] functionSummaries = { }; 
	functionPages = ( p : pagePaths[p] | p <- pagePaths, functionPage(_,_) := p );
	println("Extracting <size(functionPages)> function summary pages");
	int count = 0;	
	for (p <- functionPages, functionPage(bn,fn) := p, l := functionPages[p]) {
		for (fs <- extractFunctionSummary(bn,fn,l)) {
			functionSummaries += fs[@from=l];
		}  
		count += 1;
		if (count % 100 == 0) println("Extracted <count> function summary pages");
	}
	println("Finished extracting function summary pages, extracted <size(functionSummaries)> summaries");
	saveFunctionSummaries(functionSummaries);
	return functionSummaries;
}

public set[Summary] extractConstantSummaries(map[PageType,loc] pagePaths) {	
	set[Summary] constantSummaries = { };
	constantPages = ( p : pagePaths[p] | p <- pagePaths, constantPage(_) := p );
	println("Extracting <size(constantPages)> constant summary pages");
	int count = 0;
	for (p <- constantPages, constantPage(bn) := p, l := constantPages[p]) {
		for (cs <- extractConstantSummary(bn,l)) {
			constantSummaries += cs[@from=l];
		}
		count += 1;
		if (count % 100 == 0) println("Extracted <count> constant summary pages");
	}
	println("Finished extracting constant summary pages, extracted <size(constantSummaries)> summaries");
	saveConstantSummaries(constantSummaries);
	return constantSummaries;
}

public set[Summary] extractClassSummaries(map[PageType,loc] pagePaths) {	
	set[Summary] classSummaries = { };
	classPages = ( p : pagePaths[p] | p <- pagePaths, classPage(_,_) := p );
	println("Extracting <size(classPages)> class summary pages");
	int count = 0;
	for (p <- classPages, classPage(bn,cn) := p, l := classPages[p]) {
		for (cs <- extractClassSummary(bn,cn,l)) {
			classSummaries += cs[@from=l];
		}
		count += 1;
		if (count % 100 == 0) println("Extracted <count> class summary pages");
	}
	println("Finished extracting class summary pages, extracted <size(classSummaries)> class, constant, and field summaries");
	saveClassSummaries(classSummaries);
	return classSummaries;
}

public set[Summary] extractMethodSummaries(map[PageType,loc] pagePaths) {	
	set[Summary] methodSummaries = { };
	methodPages = ( p : pagePaths[p] | p <- pagePaths, methodPage(_,_,_) := p );
	println("Extracting <size(methodPages)> method summary pages");
	int count = 0;
	for (p <- methodPages, methodPage(bn,cn,mn) := p, l:= methodPages[p]) {
		for (ms <- extractMethodSummary(bn,cn,mn,l)) {
			methodSummaries += ms[@from=l];
		}
		count += 1;
		if (count % 100 == 0) println("Extracted <count> method summary pages");
	}
	println("Finished extracting method summary pages, extracted <size(methodSummaries)> method and function summaries");
	saveMethodSummaries(methodSummaries);
	return methodSummaries;
}

public void extractSummaries(map[PageType,loc] pagePaths) {	
	extractFunctionSummaries(pagePaths);
	extractConstantSummaries(pagePaths);
	extractClassSummaries(pagePaths);
	extractMethodSummaries(pagePaths);
}


public str flattenNodes(node topNode) {
	str res = "";
	void traverse(node n) {
		if (getName(n) == "text" && arity(n) == 1 && str s := getChildren(n)[0]) {
			res += s;
		} else if (getName(n) == "br") {
			res += "\n";
		} else {
			nChildren = getChildren(n);
			for (idx <- index(nChildren)) {
				if (node nChild := nChildren[idx]) {
					traverse(nChild);
				} else if (list[node] nChilds := nChildren[idx]) {
					for (nChild <- nChilds) traverse(nChild);
				}
			}
		}
	}
	
	traverse(topNode);
	return res;
}