@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::util::Corpus

import lang::php::stats::Stats;
import lang::php::config::Config;

import String;
import IO;
import Exception;
import List;
import Set;

alias Corpus = map[str Product, str Version];

public data RuntimeException
	= productNotFound(str product, str version, loc productDir)
	| versionNotFound(str product, str version)
	| productNotFound(str product)
	;
	 
private loc extraCorpusRoot = baseLoc + "corpus-extra";
private loc pluginRoot = corpusRoot + "WordPressPlugins";

private set[str] products() {
	if (useBinaries)
		return { pn | l <- parsedDir.ls, "pt" == l.extension, /<pn:[^\-]+>-.*/ := l.file };
	else
		return { l.file | l <- corpusRoot.ls, isDirectory(l) };
}
					   
private rel[str,str] versions() {
	if (useBinaries)
		return { < pn, vn > | l <- parsedDir.ls, "pt" == l.extension, /<pn:[^\-]+>-<vn:.+>[.]pt/ := l.file };
	else
		return { < p, v> | p <- products(), l <- (corpusRoot+p).ls, isDirectory(l), /[^\-_][-_]<v:.+>/ := l.file };
}

private set[str] versions(str p) {
	if (useBinaries)
		return { vn | l <- parsedDir.ls, "pt" == l.extension, /<pn:[^\-]+>-<vn:.+>[.]pt/ := l.file, p == pn };
	else
		return { v | p in products(), l <- (corpusRoot+p).ls, isDirectory(l), /[^\-_][-_]<v:.+>/ := l.file };
}

//private rel[str,str] plugins = { < "Akismet", "2.5.5" >, < "All-In-One-SEO-Pack","1.6.14.2" >,
//								 < "BCMS", "a1" >, < "BSocial", "1.0-trunk" >,
//								 < "CDyne-Call-Me", "1.0" >, < "Contact-Form-7", "3.1.1" >,
//								 < "DX-Delete-Attached-Media", "0.4" >, < "Jetpack", "1.2.4" >,
//								 < "PrettyPhoto-Media", "1.0" >, < "SI-Contact-Form", "3.1.5.2" >,
//								 < "The-Subtitle", "1.0" >, < "WordPress-Importer", "0.6" > };                                   
//
//private set[str] mwversions = { "1.7.1", "1.7.3", "1.8.2", "1.8.4", "1.8.5", "1.9.0", "1.9.1", "1.9.2", "1.9.3", "1.9.4", "1.9.5", "1.9.6",
//								"1.10.0", "1.10.1", "1.10.2", "1.10.3", "1.10.4", "1.11.0", "1.11.1", "1.11.2", "1.12.0", "1.12.1", "1.12.2",
//								"1.12.3", "1.12.4", "1.13.0", "1.13.1", "1.13.2", "1.13.3", "1.13.4", "1.13.5", "1.14.0", "1.14.1", "1.15.0",
//								"1.15.1", "1.15.2", "1.15.3", "1.15.4", "1.15.5", "1.16.0", "1.16.1", "1.16.2", "1.16.3", "1.16.4", "1.16.5",
//								"1.17.0", "1.17.1", "1.17.2", "1.17.3", "1.18.0", "1.18.1", "1.6.12", "1.18.2"};

public bool corpusItemExists(str product, str version) {
	if (product in products()) {
		if (version in versions(product)) {
			loc productRoot = corpusRoot + product + "<toLowerCase(product)>-<version>";
			if (exists(productRoot)) return true;
			productRoot = corpusRoot + product + "<toLowerCase(product)>_<version>";
			if (exists(productRoot)) return true;
			productRoot = corpusRoot + product + "<product>-<version>";
			if (exists(productRoot)) return true;
			productRoot = corpusRoot + product + "<product>_<version>";
			if (exists(productRoot)) return true;
			return false;
		}
		return false;
	}
	return false;
}

public loc getCorpusItem(str product, str version) {
	if (product in products()) {
		if (version in versions(product)) {
			loc productRoot = corpusRoot + product + "<toLowerCase(product)>-<version>";
			if (exists(productRoot)) return productRoot;
			productRoot = corpusRoot + product + "<toLowerCase(product)>_<version>";
			if (exists(productRoot)) return productRoot;
			productRoot = corpusRoot + product + "<product>-<version>";
			if (exists(productRoot)) return productRoot;
			productRoot = corpusRoot + product + "<product>_<version>";
			if (exists(productRoot)) return productRoot;
			throw productNotFound(product, version, productRoot);
		}
		throw versionNotFound(product, version);
	}
	throw productNotFound(product);
}

// provide an alias for getCorpusItem, it isn't the most obvious name for what it does
public loc getSystemLoc(str product, str version) = getCorpusItem(product, version);

//public loc getPlugin(str plugin, str version) {
//	if (plugin in plugins<0>) {
//		if (version in plugins[plugin]) {
//			loc pluginDir = pluginRoot + "<toLowerCase(plugin)>-<version>";
//			if (exists(pluginDir)) return pluginDir;
//			throw productNotFound(plugin, version, productRoot);
//		}
//		throw versionNotFound(plugin, version);
//	}
//	throw productNotFound(plugin);
//}
//
//public loc getMWVersion(str version) {
//	if (version in mwversions) {
//		loc productRoot = extraCorpusRoot + "MediaWiki" + "mediawiki-<version>";
//		if (exists(productRoot)) return productRoot;
//		throw productNotFound("MediaWiki", version, productRoot);
//	}
//	throw versionNotFound("MediaWiki", version);
//}

public set[str] getProducts() = products();

//public set[str] getPlugins() = plugins<0>;

public set[str] getVersions(str product) {
	if (product in products())
		return versions(product);
	throw productNotFound(product);
}

public list[str] getSortedVersions(str product) = sort(toList(getVersions(product)), compareVersion);

//public set[str] getPluginVersions(str plugin) {
//	if (plugin in plugins<0>)
//		return plugins[plugin];
//	throw productNotFound(plugin);
//}

//public set[str] getMWVersions() = mwversions;

public bool compareVersion(str v1, str v2) {
	v1a = 0; v1b = 0; v1c = 0;
	v2a = 0; v2b = 0; v2c = 0;
	
	if(/0*<a1:\d+>[.]0*<b1:\d+>[.]0*<c1:\d+>/ := v1) {
		v1a = toInt(a1); v1b = toInt(b1); v1c = toInt(c1);
	} else if(/0*<a1:\d+>[.]0*<b1:\d+>/ := v1) {
		v1a = toInt(a1); 
		try {
			v1b = toInt(b1);
		} catch _ : {
			println("Error, cannot convert <b1> to an int");
			throw "AAAAAAAAAAAAAAAA";
		}
	} else if (/0*<a1:\d+>/ := v1) {
		v1a = toInt(a1);
	}
	
	if(/<a1:\d+>[.]<b1:\d+>[.]<c1:\d+>/ := v2) {
		v2a = toInt(a1); v2b = toInt(b1); v2c = toInt(c1);
	} else if(/<a1:\d+>[.]<b1:\d+>/ := v2) {
		v2a = toInt(a1); v2b = toInt(b1);
	} else if (/0*<a1:\d+>/ := v2) {
		v2a = toInt(a1);
	}
	
	if (v1a < v2a) return true;
	if (v1a == v2a && v1b < v2b) return true;
	if (v1a == v2a && v1b == v2b && v1c < v2c) return true;
	return false;
}

public map[str,str] missingCorpusItems(map[str,str] corpus) {
	return ( p : v | p <- corpus, v := corpus[p], !corpusItemExists(p,v) ); 
}

public str bundleCorpusItems(map[str,str] corpus, str corpusName) {
	list[str] corpusPaths = [ ];
	for (p <- corpus, v := corpus[p]) {
		itemPath = getCorpusItem(p,v);
		sysAndVersion = itemPath.path[size(corpusRoot.path)+1..];
		corpusPaths = corpusPaths + sysAndVersion;
	}
	return "zip -r <corpusName>.zip " + intercalate(" ", corpusPaths);
}

public map[str Product, str Version] getLatestVersionsByVersionNumber() {
	versionsRel = loadVersionsCSV();
	return ( p : last(vl)[0] | p <- versionsRel<0>, vl := sort([ <v,d> | <v,d,_,_> <- versionsRel[p] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return compareVersion(t1[0],t2[0]); }) );
}

public map[str Product, str Version] getLatestPHP4VersionsByVersionNumber() {
	versionsRel = loadVersionsCSV();
	return ( p : last(v4l)[0] | p <- versionsRel<0>, v4l := sort([ <v,d> | <v,d,pv,_> <- versionsRel[p], "4" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return compareVersion(t1[0], t2[0]); }), !isEmpty(v4l) );
}

public map[str Product, str Version] getLatestPHP5VersionsByVersionNumber() {
	versionsRel = loadVersionsCSV();
	return ( p : last(v5l)[0] | p <- versionsRel<0>, v5l := sort([ <v,d> | <v,d,pv,_> <- versionsRel[p], "5" == pv[0] ],bool(tuple[str,str] t1, tuple[str,str] t2) { return compareVersion(t1[0],t2[0]); }), !isEmpty(v5l) );
}

public map[str Product, str Version] getLatestVersions() = getLatestVersionsByVersionNumber();

public map[str Product, str Version] getLatestPHP4Versions() = getLatestPHP4VersionsByVersionNumber();

public map[str Product, str Version] getLatestPHP5Versions() = getLatestPHP5VersionsByVersionNumber();

