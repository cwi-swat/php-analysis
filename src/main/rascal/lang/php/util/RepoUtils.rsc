module lang::php::util::RepoUtils

import util::git::Git;
import lang::php::util::Utils;
import lang::php::ast::System;

public void buildTags(str product, loc repoPath) {
    tags = getTags(repoPath);
    for (t <- tags) {
        switchToTag(repoPath, t);
        buildBinaries(product, t, repoPath, addLocationAnnotations=true);
    }
}

public void patchTags(str product, loc repoPath) {
    tags = getTags(repoPath);
    for (t <- tags) {
        switchToTag(repoPath, t);
        patchBinaries(product, t);
    }
}

public rel[str version, loc l] collectParseErrors(str product, loc repoPath) {
    rel[str version, loc l] errors = { };
    tags = getTags(repoPath);
    for (t <- tags) {
        switchToTag(repoPath, t);
        pt = loadBinary(product, t);
        errors = errors + { < t, e > | e <- errorScripts(pt) };
    }
    return errors;
}