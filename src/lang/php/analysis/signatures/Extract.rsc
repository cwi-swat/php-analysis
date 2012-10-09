module lang::php::analysis::signatures::Extract

import IO;
import Node;
import Set;
import lang::html::IO;
import lang::php::analysis::NamePaths;

private loc defaultStart = |http://www.php.net/manual/en/funcref.php|;

public map[NamePath,loc] getLibraryPages() = getLibraryPages(defaultStart);

public map[NamePath,loc] getLibraryPages(loc startingLoc) {
	map[NamePath,loc] pathPages = ( );
	
	// First, get back the root of the library documentation
	node srctxt = readHTMLFile(startingLoc);
	
	// Now, extract out the names of the "books", which are the starting points for
	// the descriptions of the various libraries
	set[node] books = { n | /node n <- srctxt, getName(n) == "a", "href" in getAnnotations(n), str s := getAnnotations(n)["href"], /book\./ := s  };
	
	int limiter = 0;
	
	// Now, go through each, getting the functions in each
	for (book <- books, str bookhref := getAnnotations(book)["href"], limiter < 10) {
		bookloc = startingLoc.parent + bookhref;
		booktxt = readHTMLFile(bookloc);

		// Extract out locations of function pages
		set[node] funs = { n | /node n <- booktxt, getName(n) == "a", "href" in getAnnotations(n), str s := getAnnotations(n)["href"], /function\./ := s, "a"(l) := n, [_*,"img"(),_*] !:= l };
		pathPages += ( [function(funname)] : startingLoc.parent + funhref | fun <- funs, str funhref := getAnnotations(fun)["href"], /function\.<funname:.*>\.php/ := funhref );
		println("Added <size(funs)> function pages for book <book>");
		
		// Extract out the class pages; we need this info to find the method pages as well
		set[node] classes = { n | /node n <- booktxt, getName(n) == "a", "href" in getAnnotations(n), str s := getAnnotations(n)["href"], /class\./ := s, "a"(l) := n, [_*,"img"(),_*] !:= l };
		pathPages += ( [NamePart::class(classname)] : startingLoc.parent + classhref | class <- classes, str classhref := getAnnotations(class)["href"], /class\.<classname:.*>\.php/ := classhref );
		println("Added <size(classes)> class pages for book <book>");
		
		// For each class, extract out the method pages
		for (class <- classes, str classhref := getAnnotations(class)["href"], /class\.<classname:.*>\.php/ := classhref) {
			set[node] methods = { n | /node n <- booktxt, getName(n) == "a", "href" in getAnnotations(n), str s := getAnnotations(n)["href"], /<classname>\..*\.php/ := s, "a"(l) := n, [_*,"img"(),_*] !:= l };
			pathPages += ( [NamePart::class(classname),NamePart::method(methodname)] : startingLoc.parent + methodhref | method <- methods, str methodhref := getAnnotations(method)["href"], /<classname>\.<methodname:.*>\.php/ := methodhref );
			println("Added <size(methods)> methods for class <classname>");
		}	
		
		limiter += 1;
	}
	
	return pathPages;
}

data SummaryParam;
data Summary = functionSummary(str functionName, list[SummaryParam] params, bool returnsRef, str returnType, bool altersGlobals, list[str] throwsTypes);

public Summary extractFunctionSummary(str functionName, loc functionLoc) {
	node ftxt = readHTMLFile(functionLoc);
	set[node] matches = { n | /node n := pageText, getName(n) == "div", "id" in getAnnotations(n), getAnnotations(n)["id"] == "function.<functionName>" };
	for (match <- matches) {
		;
	}
}

public Summary extractClassSummary(str className, loc classLoc) {
	node ctxt = readHTMLFile(functionLoc);
}

public Summary extractMethodSummary(str className, str methodName, loc methodLoc) {
	node mtxt = readHTMLFile(methodLoc);
}

public map[NamePath,Summary] extractSummaries(map[NamePath,loc] pagePaths) {

}