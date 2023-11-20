module lang::php::analysis::composer::Composer

import lang::json::IO;
import util::Maybe;
import String;
import Node;
import IO;
import DateTime;
import Exception;

import lang::php::analysis::composer::VersionSyntax;

loc wp = |file:///Users/hillsma/PHPAnalysis/systems/WordPress/package.json|;

data Composer 
    = composer(
        Maybe[tuple[str vendorName, str projectName]] name,
        Maybe[str] description,
        ComposerVersion version,
        str packageType,
        list[str] keywords,
        Maybe[str] homepage,
        str readme,
        Maybe[datetime] releaseDateTime,
        list[str] license,
        list[Author] authors,
        map[str,str] support,
        list[Funding] funding,
        rel[str packageType, str vendorName, str projectName, PackageVersionConstraint constraint] packageDependencies,
        rel[str packageType, str dependencyName, PackageVersionConstraint constraint] phpDependencies,
        rel[str autoloadType, str namespace, str path] autoloadConfig,
        rel[str autoloadType, str namespace, str path] autoloadDevConfig,
        list[str] includePaths,
        Maybe[str] targetDir,
        Maybe[str] minimumStability,
        Maybe[bool] preferStable)
    | composerLoadError(str s)
    | composerLoadError(value v, str s)
    ;

data ComposerVersion
    = version(int major, int minor, int patch)
    | version(int major, int minor, int patch, VersionSuffix suffix)
    | version(int major, int minor, int patch, VersionSuffix suffix, int suffixNum)
    | noVersion()
    ;

data VersionSuffix = dev() | patch() | alpha() | beta() | rc();

data Author = author(Maybe[str] name, Maybe[str] email, Maybe[str] homepage, Maybe[str] role);

data Funding = projectFunding(str typeOfFunding, str fundingURL);

data PackageType = requires();

data Exception = ComposerLoadError(str s) | ComposerLoadError(value v, str s);

public Composer loadComposerFile(loc l, bool justPublishedPackages = false) {
    map[str,value] js = ( );
    try {
        js = readJSON(#map[str,value], l);
    } catch IO(s): {
        return composerLoadError(s);
    }
    
    // Extract the name, which is given as vendor/project
    // See https://getcomposer.org/doc/04-schema.md#name
    // This is required for published packages. 
    nameTuple = nothing();
    if ("name" in js) {
        if (str s := js["name"], /^<vn:[^\/]*>\/<pn:.*>$/ := s) {
            nameTuple = just( < vn, pn > );
        } else {            
            return composerLoadError(js["name"], "Invalid name format");
        }
    } else {
        if (justPublishedPackages) {
            return composerLoadError("Name property missing from composer.json");
        }
    }

    // Extract the project description
    // See https://getcomposer.org/doc/04-schema.md#description
    // This is required for published packages.
    desc = nothing();
    if ("description" in js) {
        if (str s := js["description"]) {
            desc = just(s);
        } else {
            return composerLoadError(js["description"], "Invalid description format");
        }
    } else {
        if (justPublishedPackages) {
            return composerLoadError("Description property missing from composer.json");
        }
    }

    // Extract the project version. Note that this is usually missing, and is instead
    // linked to the related Git tag for the release.
    // See https://getcomposer.org/doc/04-schema.md#version
    // This is optional
    v = noVersion();
    if ("version" in js) {
        if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p));
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>$/ := s) {
            v = version(toInt(m),toInt(n),0);
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-dev$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),dev());
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-dev<q:\d+>$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),dev(),toInt(q));
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-patch$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),patch());
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-patch<q:\d+>$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),patch(),toInt(q));
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-p$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),patch());
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-p<q:\d+>$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),patch(),toInt(q));
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-alpha$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),alpha());
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-alpha<q:\d+>$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),alpha(),toInt(q));
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-a$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),alpha());
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-a<q:\d+>$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),alpha(),toInt(q));
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-beta$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),beta());
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-beta<q:\d+>$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),beta(),toInt(q));
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-b$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),beta());
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-b<q:\d+>$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),beta(),toInt(q));
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-RC$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),rc());
        } else if (str s := js["version"], /[v]?<m:\d+>\.<n:\d+>\.<p:\d+>\-RC<q:\d+>$/ := s) {
            v = version(toInt(m),toInt(n),toInt(p),rc(),toInt(q));
        } else {
            return composerLoadError(js["version"], "Invalid version format");
        }
    }

    // Extract the project type. This defaults to "library".
    // See https://getcomposer.org/doc/04-schema.md#type
    // This is optional, and defaults to library
    t = "library";
    if ("type" in js) {
        if (str s := js["type"]) {
            t = s;
        } else {
            return composerLoadError(js["library"], "Invalid library format");
        }
    }

    // Extract project keywords. 
    // See https://getcomposer.org/doc/04-schema.md#keywords
    // This is optional
    list[str] keywords = [ ];
    if ("keywords" in js) {
        if (list[str] ks := js["keywords"]) {
            keywords = ks;
        } else {
            return composerLoadError(js["keywords"], "Invalid keywords format");
        }
    }

    // Extract project homepage.
    // See https://getcomposer.org/doc/04-schema.md#homepage
    // This is optional
    homepage = nothing();
    if ("homepage" in js) {
        if (str s := js["homepage"]) {
            homepage = just(s);
        } else {
            return composerLoadError(js["homepage"], "Invalid homepage format");
        }
    }
    
    // Extract project readme file
    // See https://getcomposer.org/doc/04-schema.md#readme
    // This is optional
    readme = "README.md";
    if ("readme" in js) {
        if (str s := js["readme"]) {
            readme = s;
        } else {
            return composerLoadError(js["readme"], "Invalid readme format");
        }
    }

    // Extract project time
    // See https://getcomposer.org/doc/04-schema.md#time
    // This is optional
    // TODO: This needs to be checked, we need to find a package
    // that includes datetime information.
    releaseDateTime = nothing();
    if ("time" in js) {
        if (str s := js["time"]) {
            try {
                releseDateTime = just(parseDateTime(s,"YYYY-MM-DD HH:MM:SS"));
            } catch DateTimeParsingError(_): {
                try {
                    releaseDateTime = just(parseDate(s,"YYYY-MM-DD"));
                } catch DateTimeParsingError(_): {
                    return composerLoadError(js["time"], "Invalid datetime format");
                }
            }
        } else {
            return composerLoadError(js["time"], "Invalid datetime format");
        }
    }

    // Extract project license
    // See https://getcomposer.org/doc/04-schema.md#license
    // This is optional
    list[str] license = [ ];
    if ("license" in js) {
        if (list[str] ss := js["license"]) {
            license = ss;
        } else if (str s := js["license"]) {
            license = [ s ];
        } else {
            return composerLoadError(js["license"], "Invalid license format");
        }
    }

    // Extract project authors
    // See https://getcomposer.org/doc/04-schema.md#authors
    // This is optional
    list[Author] authors = [ ];
    if ("authors" in js) {
        if (list[node] ats := js["authors"]) {
            for (atr <- ats) {
                authName = if(atr has name, str s := atr.name) just(s); else nothing();
                authEmail = if(atr has email, str s := atr.email) just(s); else nothing();
                authHomepage = if (atr has homepage, str s := atr.homepage) just(s); else nothing();
                authRole = if (atr has role, str s := atr.role) just(s); else nothing();
                authors = authors + author(authName, authEmail, authHomepage, authRole);
            }
        } else {
            return composerLoadError(js["authors"], "Invalid authors format");
        }
    }

    // Extract project support information
    // See https://getcomposer.org/doc/04-schema.md#support
    // This is optional
    map[str,str] support = ( );
    if ("support" in js) {
        if (node spt := js["support"]) {
            ps = getKeywordParameters(spt);
            for (p <- ps) {
                support[p] = "<ps[p]>";
            }
        } else {
            return composerLoadError(js["support"], "Invalid support format");
        }
    }

    // Extract project funding information
    // See https://getcomposer.org/doc/04-schema.md#funding
    // TODO: This needs to be checked, we need to find a package
    // that includes funding information.
    // This is optional
    list[Funding] funds = [ ];
    if ("funding" in js) {
        if (list[node] fnd := js["funding"]) {
            for (f <- fnd, str fn := f.\type, str fl := f.url) {
                funds = funds + projectFunding(fn,fl);
            }
        } else {
            return composerLoadError(js["funding"], "Invalid funding format");
        }
    }

    // Extract packages info 
    // See https://getcomposer.org/doc/04-schema.md#package-links
    // This is optional
    // TODO: Parse the package info to get more accurate info about allowable versions
    rel[str packageType, str vendorName, str projectName, PackageVersionConstraint constraint] packageDependencies = { };
    rel[str packageType, str dependencyName, PackageVersionConstraint constraint] phpDependencies = { };
    set[str] packageTypes = { "require", "require-dev", "conflict", "replace", "provide", "suggest" };
    for (packageType <- packageTypes) {
        if (packageType in js) {
            if (node pi := js[packageType]) {
                ps = getKeywordParameters(pi);
                // println(ps);
                for (p <- ps) {
                    if (str s := p, /^<vn:[^\/]*>\/<pn:.*>$/ := s) {
                        if (packageType == "suggest") {
                            packageDependencies = packageDependencies + < packageType, vn, pn, suggestion("<ps[p]>") >;
                        } else {
                            packageDependencies = packageDependencies + < packageType, vn, pn, parseConstraint("<ps[p]>") >;
                        }
                    } else if (str s := p) {
                        if (packageType == "suggest") {
                            phpDependencies = phpDependencies + < packageType, s, suggestion("<ps[p]>") >;
                        } else {
                            phpDependencies = phpDependencies + < packageType, s, parseConstraint("<ps[p]>") >;
                        }
                    } else {
                        ; // throw an exception, bad format
                    }
                }
            } else {
                return composerLoadError(js[packageType], "Invalid format for package type <packageType>");
            }
        }
    }

    // Extract Autoloader info
    // See https://getcomposer.org/doc/04-schema.md#autoload
    // This is optional
    rel[str autoloadType, str namespace, str path] autoloadConfig = { };    
    if ("autoload" in js, node jsa := js["autoload"]) {
        ps = getKeywordParameters(jsa);
        if ("psr-4" in ps, node ali := ps["psr-4"]) {
            psr4keys = getKeywordParameters(ali);
            for (pkg <- psr4keys) {
                if (str s := psr4keys[pkg]) {
                    autoloadConfig = autoloadConfig + < "psr-4", pkg, s >;
                } else if (list[str] ss := psr4keys[pkg]) {
                    autoloadConfig = autoloadConfig + { < "psr-4", pkg, s > | s <- ss };
                } else {
                    return composerLoadError(psr4keys[pkg], "Invalid format for PSR-4 package");
                }
            }
        } else if ("psr-0" in ps, node ali := ps["psr-0"]) {
            psr0keys = getKeywordParameters(ali);
            for (pkg <- psr0keys) {
                if (str s := psr0keys[pkg]) {
                    autoloadConfig = autoloadConfig + < "psr-0", pkg, s >;
                } else if (list[str] ss := psr0keys[pkg]) {
                    autoloadConfig = autoloadConfig + { < "psr-0", pkg, s > | s <- ss };
                } else {
                    return composerLoadError(psr0keys[pkg], "Invalid format for PSR-0 package");
                }
            }
        } else if ("classmap" in ps, list[str] cmap := ps["classmap"]) {
            for (cn <- cmap) {
                autoloadConfig = autoloadConfig + < "classmap", "", cn >;
            }
        } else if ("files" in ps, list[str] fmap := ps["files"]) {
            for (fn <- fmap) {
                autoloadConfig = autoloadConfig + < "files", "", fn >;
            }
        } else {
            return composerLoadError(ps, "Invalid autoloader config");
        }
    }

    // Extract this info for dev
    // See https://getcomposer.org/doc/04-schema.md#autoload-dev
    // This is optional
    rel[str autoloadType, str namespace, str path] autoloadDevConfig = { };    
    if ("autoload-dev" in js, node jsa := js["autoload-dev"]) {
        ps = getKeywordParameters(jsa);
        if ("psr-4" in ps, node ali := ps["psr-4"]) {
            psr4keys = getKeywordParameters(ali);
            for (pkg <- psr4keys) {
                if (str s := psr4keys[pkg]) {
                    autoloadDevConfig = autoloadDevConfig + < "psr-4", pkg, s >;
                } else if (list[str] ss := psr4keys[pkg]) {
                    autoloadDevConfig = autoloadDevConfig + { < "psr-4", pkg, s > | s <- ss };
                } else {
                    return composerLoadError(psr4keys[pkg], "Invalid format for PSR-4 package");
                }
            }
        } else if ("psr-0" in ps, node ali := ps["psr-0"]) {
            psr0keys = getKeywordParameters(ali);
            for (pkg <- psr0keys) {
                if (str s := psr0keys[pkg]) {
                    autoloadDevConfig = autoloadDevConfig + < "psr-0", pkg, s >;
                } else if (list[str] ss := psr0keys[pkg]) {
                    autoloadDevConfig = autoloadDevConfig + { < "psr-0", pkg, s > | s <- ss };
                } else {
                    return composerLoadError(psr0keys[pkg], "Invalid format for PSR-0 package");
                }
            }
        } else if ("classmap" in ps, list[str] cmap := ps["classmap"]) {
            for (cn <- cmap) {
                autoloadDevConfig = autoloadDevConfig + < "classmap", "", cn >;
            }
        } else if ("files" in ps, list[str] fmap := ps["files"]) {
            for (fn <- fmap) {
                autoloadDevConfig = autoloadDevConfig + < "files", "", fn >;
            }
        } else {
            return composerLoadError(ps, "Invalid autoloader config");
        }
    }

    // Extract include path
    // See https://getcomposer.org/doc/04-schema.md#include-path
    // This is optional and deprecated
    list[str] includePaths = [ ];
    if ("include-path" in js, list[str] ips := js["include-path"]) {
        includePaths = ips;
    }

    // Extract target directory
    // See https://getcomposer.org/doc/04-schema.md#target-dir
    // This is optional
    Maybe[str] targetDir = nothing();
    if ("target-dir" in js) {
        if (str s := js["target-dir"]) {
            targetDir = just(s);
        } else {
            return composerLoadError(js["target-dir"], "Invalid target-dir setting");
        }
    }

    // Extract minimum stability
    // See https://getcomposer.org/doc/04-schema.md#minimum-stability
    // This is optional
    Maybe[str] minimumStability = nothing();
    if ("minimum-stability" in js) {
        if (str s := js["minimum-stability"]) {
            minimumStability = just(s);
        } else {
            return composerLoadError(js["minimum-stability"], "Invalid minimum-stability setting");
        }
    }

    // Extract prefer stable flag
    // See https://getcomposer.org/doc/04-schema.md#root-package
    // This is optional
    Maybe[bool] preferStable = nothing();
    if ("prefer-stable" in js) {
        if (bool b := js["prefer-stable"]) {
            preferStable = just(b);
        } else {
            return composerLoadError(js["prefer-stable"], "Invalid prefer-stable setting");
        }
    }

    // Extract repositories info
    // See https://getcomposer.org/doc/04-schema.md#repositories
    // TODO: Add this later!


    Composer c = composer(
        nameTuple, 
        desc, 
        v, 
        t, 
        keywords,
        homepage,
        readme,
        releaseDateTime,
        license,
        authors,
        support,
        funds,
        packageDependencies,
        phpDependencies,
        autoloadConfig,
        autoloadDevConfig,
        includePaths,
        targetDir,
        minimumStability,
        preferStable );
    return c;
}