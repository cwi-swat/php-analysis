module lang::php::analysis::includes::LibraryIncludes

data LibItem = library(str name, str path, str desc);

public set[LibItem] getKnownLibraries() {
	// These need to be moved into configuration, but just put them here for now
	return {
		//library("Mail", "Mail.php", "Mailer")
	};	
}

