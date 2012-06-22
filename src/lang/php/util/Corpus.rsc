@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::util::Corpus

import String;
import IO;
import Exception;
import lang::php::util::Config;

public data RuntimeException
	= productNotFound(str product, str version, loc productDir)
	| versionNotFound(str product, str version)
	| productNotFound(str product)
	;
	 
private loc corpusRoot = |file:///export/scratch1/hills/corpus|;
private loc extraCorpusRoot = projroot + "corpus-extra";
private loc pluginRoot = corpusRoot + "WordPressPlugins";

private set[str] products() = { l.file | l <- corpusRoot.ls, isDirectory(l) };
					   
private rel[str,str] versions() = { < p, v> | p <- products(), l <- (corpusRoot+p).ls, isDirectory(l), /[^\-]-<v:.+>/ := l.file };

private set[str] versions(str p) = { v | p in products(), l <- (corpusRoot+p).ls, isDirectory(l), /[^\-]-<v:.+>/ := l.file };

private rel[str,str] plugins = { < "Akismet", "2.5.5" >, < "All-In-One-SEO-Pack","1.6.14.2" >,
								 < "BCMS", "a1" >, < "BSocial", "1.0-trunk" >,
								 < "CDyne-Call-Me", "1.0" >, < "Contact-Form-7", "3.1.1" >,
								 < "DX-Delete-Attached-Media", "0.4" >, < "Jetpack", "1.2.4" >,
								 < "PrettyPhoto-Media", "1.0" >, < "SI-Contact-Form", "3.1.5.2" >,
								 < "The-Subtitle", "1.0" >, < "WordPress-Importer", "0.6" > };                                   

private set[str] mwversions = { "1.7.1", "1.7.3", "1.8.2", "1.8.4", "1.8.5", "1.9.0", "1.9.1", "1.9.2", "1.9.3", "1.9.4", "1.9.5", "1.9.6",
								"1.10.0", "1.10.1", "1.10.2", "1.10.3", "1.10.4", "1.11.0", "1.11.1", "1.11.2", "1.12.0", "1.12.1", "1.12.2",
								"1.12.3", "1.12.4", "1.13.0", "1.13.1", "1.13.2", "1.13.3", "1.13.4", "1.13.5", "1.14.0", "1.14.1", "1.15.0",
								"1.15.1", "1.15.2", "1.15.3", "1.15.4", "1.15.5", "1.16.0", "1.16.1", "1.16.2", "1.16.3", "1.16.4", "1.16.5",
								"1.17.0", "1.17.1", "1.17.2", "1.17.3", "1.18.0", "1.18.1", "1.6.12", "1.18.2"};

public loc getCorpusItem(str product, str version) {
	if (product in products()) {
		if (version in versions(product)) {
			loc productRoot = corpusRoot + product + "<toLowerCase(product)>-<version>";
			if (exists(productRoot)) return productRoot;
			throw productNotFound(product, version, productRoot);
		}
		throw versionNotFound(product, version);
	}
	throw productNotFound(product);
}

public loc getPlugin(str plugin, str version) {
	if (plugin in plugins<0>) {
		if (version in plugins[plugin]) {
			loc pluginDir = pluginRoot + "<toLowerCase(plugin)>-<version>";
			if (exists(pluginDir)) return pluginDir;
			throw productNotFound(plugin, version, productRoot);
		}
		throw versionNotFound(plugin, version);
	}
	throw productNotFound(plugin);
}

public loc getMWVersion(str version) {
	if (version in mwversions) {
		loc productRoot = extraCorpusRoot + "MediaWiki" + "mediawiki-<version>";
		if (exists(productRoot)) return productRoot;
		throw productNotFound("MediaWiki", version, productRoot);
	}
	throw versionNotFound("MediaWiki", version);
}

public set[str] getProducts() = products();

public set[str] getPlugins() = plugins<0>;

public set[str] getVersions(str product) {
	if (product in products())
		return versions(product);
	throw productNotFound(product);
}

public set[str] getPluginVersions(str plugin) {
	if (plugin in plugins<0>)
		return plugins[plugin];
	throw productNotFound(plugin);
}

public set[str] getMWVersions() = mwversions;

public bool compareMWVersion(str v1, str v2) {
	if(/<a1:\d+>[.]<b1:\d+>[.]<c1:\d+>/ := v1) {
		if(/<a2:\d+>[.]<b2:\d+>[.]<c2:\d+>/ := v2) {
			if (toInt(a1) < toInt(a2)) return true;
			if (toInt(a1) == toInt(a2) && toInt(b1) < toInt(b2)) return true;
			if (toInt(a1) == toInt(a2) && toInt(b1) == toInt(b2) && toInt(c1) <= toInt(c2)) return true;
			return false;
		} 
	} 
}
