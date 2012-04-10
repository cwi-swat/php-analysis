module lang::php::util::Corpus

import String;
import IO;
import Exception;

public data RuntimeException
	= productNotFound(str product, str version, loc productDir)
	| versionNotFound(str product, str version)
	| productNotFound(str product)
	;
	 
private loc corpusRoot = |file:///ufs/hills/project/phpsa/corpus|;

private rel[str,str] versions = { < "Drupal", "6.25" >, < "Drupal", "7.12" >, 
								  < "Gallery", "2.3.1" >, < "Gallery", "3.0.2" >,
                                  < "Joomla", "1.5.26" >, < "Joomla", "2.5.4" >, 
                                  < "Kohana", "3.2" >, 
                                  < "MediaWiki", "1.6.12" >, < "MediaWiki", "1.18.2" >, 
                                  < "osCommerce", "2.3.1" >, 
                                  < "phpBB", "3" >,
                                  < "phpMyAdmin", "2.11.11.3-english"> , < "phpMyAdmin", "3.5.0-english" >,
                                  < "SilverStripe", "2.4.7" >,
                                  < "SquirrelMail", "1.4.22" >,
                                  < "Symfony", "2.0.12" >,
                                  < "WordPress", "3.1.4" >, < "WordPress", "3.3.1" > };
                                  
public loc getCorpusItem(str product, str version) {
	if (product in versions<0>) {
		if (version in versions[product]) {
			loc productRoot = corpusRoot + product + "<toLowerCase(product)>-<version>";
			if (exists(productRoot)) return productRoot;
			throw productNotFound(product, version, productRoot);
		}
		throw versionNotFound(product, version);
	}
	throw productNotFound(product);
}

public set[str] getProducts() = versions<0>;

public set[str] getVersions(str product) {
	if (product in versions<0>)
		return versions[product];
	throw productNotFound(product);
}