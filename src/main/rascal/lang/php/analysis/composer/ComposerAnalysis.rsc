@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::analysis::composer::ComposerAnalysis

import lang::php::analysis::composer::Composer;
import lang::php::util::Utils;
import lang::php::config::Config;
import lang::php::util::CLOC;
import lang::php::analysis::composer::VersionSyntax;

import IO;
import Set;
import ValueIO;
import String;
import List;

@doc{
    Load the composer.json file from the system at location l.
    Note that we assume this file exists.
}
public Composer extractComposerModel(loc l) = loadComposerFile(l+"composer.json");

@doc{
    Check to see if the system at location l includes a
    composer.json file.
}
public bool includesComposerFile(loc l) {
    return exists(l + "composer.json");
}

@doc{
    The base location of the Composer corpus.
}
private loc composerCorpusBase = |file:///Users/hillsma/PHPAnalysis/composer|;

@doc{
    The composer corpus. Note that not all of these systems may
    use composer -- that is part of what is being analyzed.
}
public rel[str,str,loc] composerCorpusRel() {
    return { < sln[0], sln[1], composerCorpusBase + "<sln[0]>-<sln[1]>" > | ln <- readFileLines(composerCorpusBase + "repos.txt"), !isEmpty(trim(ln)), sln := split("/", ln), size(sln) == 2};
}

public set[loc] composerCorpus = (composerCorpusRel())<2>;

@doc{
    Given a set of systems, produce a map indicating which
    systems include a composer.json file.
}
public map[loc,bool] systemHasComposerFile 
    = ( l : includesComposerFile(l) | l <- composerCorpus );

@doc{
    Given a set of systems, return the count of how many
    include a composer.json file and how many do not.
}
public tuple[int hasFile, int noFile] composerFileCounts() {
    hasFile = size({ l | l <- composerCorpus, systemHasComposerFile[l]});
    noFile = size({ l | l <- composerCorpus, !systemHasComposerFile[l]});
    return < hasFile, noFile >;
}

public map[loc, Composer] loadComposerFilesForCorpus() {
    map[loc, Composer] result = ( );
    for (l <- composerCorpus, systemHasComposerFile[l]) {
        logMessage("Loading composer file for system <l.file>", 1);
        try {
            result[l] = extractComposerModel(l);
        } catch ComposerLoadError(s): {
            logMessage("Could not load composer file for <l>, error <s>",1);
        } catch ComposerLoadError(v,s): {
            logMessage("Could not load composer file for <l>, value <v>, error <s>",1);
        }
    }
    return result;
}

public map[loc, ClocResult] slocForCorpus() {
    map[loc, ClocResult] result = ( );
    for (l <- composerCorpus) {
        cres = phpLinesOfCode(l, clocLoc);
        result[l] = cres;
    }
    return result;
}
    
public void saveSlocInfo(map[loc, ClocResult] results) {
    writeBinaryValueFile(baseLoc + "extract/clocinfo/composer-cloc.bin", results);
}

public map[loc, ClocResult] loadSlocInfo() {
    return readBinaryValueFile(#map[loc, ClocResult], baseLoc + "extract/clocinfo/composer-cloc.bin");
}

public void saveComposerInfo(map[loc, Composer] results) {
    writeBinaryValueFile(baseLoc + "extract/composer/composer-info.bin", results);
}

public map[loc, Composer] loadComposerInfo() {
    return readBinaryValueFile(#map[loc, Composer], baseLoc + "extract/composer/composer-info.bin");
}

@doc{
    Join the owner/repo info from the corpus with the computed Composer summaries.
}
public rel[str owner, str repo, Composer cinfo] linkComposerInfo(map[loc, Composer] summaries) {
    ccr = composerCorpusRel();
    return { < owner, repo, summaries[l] > | < owner, repo, l > <- ccr, l in summaries };
}

@doc{
    Join the owner/repo info from the corpus with the computed CLOC results.
}
public rel[str owner, str repo, ClocResult sloc] linkClocInfo(map[loc, ClocResult] clocMap) {
    ccr = composerCorpusRel();
    return { < owner, repo, clocMap[l] > | < owner, repo, l > <- ccr, l in clocMap };
}

public void writeSlocCSV(loc l, rel[str owner, str repo, ClocResult sloc] slocInfo) {
    ccr = composerCorpusRel();

    // Add the header line
    list[str] lines = [ "owner,repo,phpfiles,phplines,composer"];

    // Add a line for each system
    for ( < owner, repo, sloc > <- slocInfo ) {
        itemLoc = getOneFrom(ccr[owner, repo]);
        if (systemHasComposerFile[itemLoc]) {
            if (sloc is clocResult) {
                lines = lines + "<owner>,<repo>,<sloc.files>,<sloc.sourceLines>,1";
            } else {
                lines = lines + "<owner>,<repo>,0,0,1";
            }
        } else {
            if (sloc is clocResult) {
                lines = lines + "<owner>,<repo>,<sloc.files>,<sloc.sourceLines>,0";
            } else {
                lines = lines + "<owner>,<repo>,0,0,0";
            }
        }
    }

    writeFileLines(l, lines);
}

public void writeDependenciesCSV(loc l, rel[str owner, str repo, Composer cinfo] composerInfo) {
    ccr = composerCorpusRel();

    // Add the header line
    list[str] lines = [ "owner,repo,packageType,vendorName,packageName"];

    // Add a line for each system
    for ( < owner, repo, sloc > <- ccr, systemHasComposerFile[sloc], cinfo <- composerInfo[owner,repo], cinfo is composer ) {
        for (< packageType, vendorName, projectName, _> <- cinfo.packageDependencies)
            lines = lines + "<owner>,<repo>,<packageType>,<vendorName>,<projectName>";
    }

    writeFileLines(l, lines);
}

public void dependenciesCount(loc l, rel[str owner, str repo, Composer cinfo] composerInfo) {
    list[str] lines = ["owner,repo,require,require-dev,conflict,replace,provide,suggest"];
    for (<owner, repo, cinfo> <- composerInfo, cinfo is composer) {
        requireCount = size(cinfo.packageDependencies["require"]);
        requireDevCount = size(cinfo.packageDependencies["require-dev"]);
        conflictCount = size(cinfo.packageDependencies["conflict"]);
        replaceCount = size(cinfo.packageDependencies["replace"]);
        provideCount = size(cinfo.packageDependencies["provide"]);
        suggestCount = size(cinfo.packageDependencies["suggest"]);
        lines = lines + "<owner>,<repo>,<requireCount>,<requireDevCount>,<conflictCount>,<replaceCount>,<provideCount>,<suggestCount>";
    }

    writeFileLines(l, lines);
}

public void dependencyCounts(loc l, rel[str owner, str repo, Composer cinfo] composerInfo, str dependencyType) {
    list[str] lines = ["dependency,occurrences"];

    map[str,int] dependencyCounts = ( );

    for (<_, _, cinfo> <- composerInfo, cinfo is composer) {
        for ( < vendorName, projectName, _ > <- cinfo.packageDependencies[dependencyType] ) {
            dependencyName = "<vendorName>/<projectName>";
            if (dependencyName in dependencyCounts) {
                dependencyCounts[dependencyName] = dependencyCounts[dependencyName] + 1;
            } else {
                dependencyCounts[dependencyName] = 1;
            }
        }
    }

    for (dependencyName <- dependencyCounts) {
        lines = lines + "<dependencyName>,<dependencyCounts[dependencyName]>";
    }

    writeFileLines(l, lines);
}

public void requireCounts(loc l, rel[str owner, str repo, Composer cinfo] composerInfo) {
    dependencyCounts(l, composerInfo, "require");
}

public void requireDevCounts(loc l, rel[str owner, str repo, Composer cinfo] composerInfo) {
    dependencyCounts(l, composerInfo, "require-dev");
}


data ConstraintCounts
    = constraintCounts(int rawConstraint, int suggestion, int tildeConstraint, int caratConstraint, int wildcardConstraint, int logicalConstraint, int exactConstraint, int branchConstraint, int andConstraint, int orConstraint, int hyphenConstraint)
    ;

@doc{
    Summary counts of different kinds of possible Composer constraints.
}
private ConstraintCounts emptyConstraintCounts() = constraintCounts(0,0,0,0,0,0,0,0,0,0,0);

@doc{
    Extract a relation from constraint types to parsed constraints.
}
public lrel[str constraintType, PackageVersionConstraint constraint] fetchConstraintCountsRel(rel[str owner, str repo, Composer cinfo] composerInfo) {
    // First, get back all the dependency constraints in a list (so we don't lose duplicates)
    lrel[str constraintType, PackageVersionConstraint constraint] constraintList = [];

    // Second, fill the list with all the constraints. We track the dependency type too, but we
    // skip suggest dependencies since these are just textual, there are no constraints.
    for (< _, _, cinfo > <- composerInfo, cinfo is composer) {
        for ( < dependencyType, _, _, constraint > <- cinfo.packageDependencies, dependencyType != "suggest") {
            constraintList = constraintList + < dependencyType, constraint >;
        }
    }

    return constraintList;
}

@doc{
    Given a relation from constraint types to parsed constraints, compute counts for each type of constraint.
    Note that this ignores the constraint type.
}
public ConstraintCounts computeConstraintCounts(
    lrel[str constraintType, PackageVersionConstraint constraint] constraintList, set[str] constraintFilter = { }
) {
    cc = emptyConstraintCounts();

    if (size(constraintFilter) == 0) constraintFilter = toSet(constraintList<0>);

    for ( < ct, c > <- constraintList, ct in constraintFilter ) {
        if (c is rawConstraint) {
            cc.rawConstraint = cc.rawConstraint + 1;
        } else if (c is suggestion) {
            cc.suggestion = cc.suggestion + 1;
        } else if (c is tildeConstraint) {
            cc.tildeConstraint = cc.tildeConstraint + 1;
        } else if (c is caratConstraint) {
            cc.caratConstraint = cc.caratConstraint + 1;
        } else if (c is wildcardForMajorConstraint || c is wildcardForMinorConstraint || c is wildcardForPatchConstraint) {
            cc.wildcardConstraint = cc.wildcardConstraint + 1;
        } else if (c is gtConstraint || c is gtEqConstraint || c is ltConstraint || c is ltEqConstraint || c is neqConstraint) {
            cc.logicalConstraint = cc.logicalConstraint + 1;
        } else if (c is majorVersionConstraint || c is majorVersionWithPreReleaseConstraint ||
                   c is minorVersionConstraint || c is minorVersionWithPreReleaseConstraint ||
                   c is patchVersionConstraint || c is patchVersionWithPreReleaseConstraint) {
            cc.exactConstraint = cc.exactConstraint + 1;
        } else if (c is branchConstraint) {
            cc.branchConstraint = cc.branchConstraint + 1;
        } else if (c is orConstraint) {
            cc.orConstraint = cc.orConstraint + 1;
        } else if (c is andConstraint) {
            cc.andConstraint = cc.andConstraint + 1;
        } else if (c is hyphenConstraint) {
            cc.hyphenConstraint = cc.hyphenConstraint + 1;
        }
    }

    return cc;
}

