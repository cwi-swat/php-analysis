module lang::php::analysis::composer::VersionSyntax

import ParseTree;
import Exception;

// layout is lists of whitespace characters
layout MyLayout = [\t\n\ \r\f]*;

// Represent exact version numbers, with or without a stability.
// Examples include 1, 1.0, 1.0.1, and 1.0.3-RC2.
lexical ExactVersionConstraint
    = justMajor: [v]? [0-9]+ major !>> [0-9.\-]
    | majorMinor: [v]? [0-9]+ major "." [0-9]+ minor !>> [0-9.\-]
    | majorMinorPatch: [v]? [0-9]+ major "." [0-9]+ minor "." [0-9]+ patch !>> [0-9\-]
    | majorWithPreRelease: [v]? [0-9]+ major "-" { StabilityId "." }+ ids
    | majorMinorWithPreRelease: [v]? [0-9]+ major "." [0-9]+ minor  "-"{ StabilityId "." }+ ids
    | majorMinorPatchWithPreRelease: [v]? [0-9]+ major "." [0-9]+ minor "." [0-9]+ patch  "-" { StabilityId "." }+ ids
    ;

// The stability, also called a "pre-release" in the semver docs.
// This is more general than what Composer can actually accept, but
// mirrors the definition in the SemVer docs.
lexical StabilityId
    = stabilityId: [0-9A-Za-z\-]+ !>> [0-9A-Za-z\-]
    ;

// A wildcard constraint, like 1.* or 1.3.*
lexical WildcardConstraint
    = wildcardForMajor: "*" !>> [.*]
    | wildcardForMinor: [v]? [0-9]+ major "." "*" !>> [.*]
    | wildcardForPatch: [v]? [0-9]+ major "." [0-9]+ minor "." "*" 
    ;

// A branch constraint
lexical BranchConstraint
    = branchPrefix: "dev-" [0-9A-Za-z\-]+ !>> [0-9A-Za-z\-]
    | branchSuffix: [0-9A-Za-z\-.]+ ".x-dev" !>> [0-9A-Za-z\-.]
    ;

lexical TildeConstraint
    = tildeWithExact: "~" ExactVersionConstraint !>> [0-9.\-]
    ;

lexical CaratConstraint
    = caratWithExact: "^" ExactVersionConstraint !>> [0-9.\-]
    ;

// Constraints with range information, such as greater than
// or not equal operators.
syntax VersionRangeConstraint
    = greaterThan: "\>" ExactVersionConstraint constraint !>> [0-9.\-]
    | greaterThanOrEqual: "\>=" ExactVersionConstraint constraint !>> [0-9.\-]
    | lessThan: "\<" ExactVersionConstraint constraint !>> [0-9.\-]
    | lessThanOrEqual: "\<=" ExactVersionConstraint constraint !>> [0-9.\-]
    | notEqual: "!=" ExactVersionConstraint constraint !>> [0-9.\-]
    | wildcardConstraint: WildcardConstraint
    | tildeConstraint: TildeConstraint
    | caratConstraint: CaratConstraint
    | branchConstraint: BranchConstraint
    ;

start syntax VersionConstraint
    = left ( andWithSpaces: VersionConstraint c1 VersionConstraint c2
           | andWithCommas: VersionConstraint c1 "," VersionConstraint c2)
    > left ( orWithOnePipe: VersionConstraint c1 "|" VersionConstraint c2
           | orWithTwoPipes: VersionConstraint c1 "||" VersionConstraint c2)
    > left hyphenatedRange: VersionConstraint c1 "-" VersionConstraint c2
    > baseRangeConstraint: VersionRangeConstraint rc
    | baseExactConstraint: ExactVersionConstraint ec
    ;

public data PackageVersionConstraint
    = rawConstraint(str constraintText)
    | suggestion(str suggestionText)
    | tildeConstraint(PackageVersionConstraint c)
    | caratConstraint(PackageVersionConstraint c)
    | wildcardForMajorConstraint()
    | wildcardForMinorConstraint(str major)
    | wildcardForPatchConstraint(str major, str minor)
    | gtConstraint(PackageVersionConstraint c)
    | gtEqConstraint(PackageVersionConstraint c)
    | ltConstraint(PackageVersionConstraint c)
    | ltEqConstraint(PackageVersionConstraint c)
    | neqConstraint(PackageVersionConstraint c)
    | majorVersionConstraint(str major)
    | majorVersionWithPreReleaseConstraint(str major, str stability)
    | minorVersionConstraint(str major, str minor)
    | minorVersionWithPreReleaseConstraint(str major, str minor, str stability)
    | patchVersionConstraint(str major, str minor, str patch)
    | patchVersionWithPreReleaseConstraint(str major, str minor, str patch, str stability)
    | branchConstraint(str branch)
    | andConstraint(PackageVersionConstraint left, PackageVersionConstraint right)
    | orConstraint(PackageVersionConstraint left, PackageVersionConstraint right)
    | hyphenConstraint(PackageVersionConstraint left, PackageVersionConstraint right)
    ;

private PackageVersionConstraint parseExactVersionConstraint(ExactVersionConstraint evc) {
    if (evc is justMajor) {
        return majorVersionConstraint("<evc.major>");
    } else if (evc is majorMinor) {
        return minorVersionConstraint("<evc.major>", "<evc.minor>");
    } else if (evc is majorMinorPatch) {
        return patchVersionConstraint("<evc.major>", "<evc.minor>", "<evc.patch>");
    } else if (evc is majorWithPreRelease) {
        return majorVersionWithPreReleaseConstraint("<evc.major>", "<evc.ids>");
    } else if (evc is majorMinorWithPreRelease) {
        return minorVersionWithPreReleaseConstraint("<evc.major>", "<evc.minor>", "<evc.ids>");
    } else if (evc is majorMinorPatchWithPreRelease) {
        return patchVersionWithPreReleaseConstraint("<evc.major>", "<evc.minor>", "<evc.patch>", "<evc.ids>");
    } else {
        return rawConstraint("<evc>");
    }
}

private PackageVersionConstraint parseWildcardConstraint(WildcardConstraint wc) {
    if (wc is wildcardForMajor) {
        return wildcardForMajorConstraint();
    } else if (wc is wildcardForMinor) {
        return wildcardForMinorConstraint("<wc.major>");
    } else if (wc is wildcardForPatch) {
        return wildcardForPatchConstraint("<wc.major>", "<wc.minor>");
    } else {
        return rawConstraint("<wc>");
    }
}

public PackageVersionConstraint parseConstraint(str constraintText) {
    try {
        return parseConstraint(parse(#VersionConstraint, constraintText));
    } catch ParseError(loc _): {
        return rawConstraint(constraintText);
    }
}

public PackageVersionConstraint parseConstraint(VersionConstraint vc) {
    switch(vc) {
        case (VersionConstraint)`~<ExactVersionConstraint evc>`: {
            return tildeConstraint(parseExactVersionConstraint(evc));
        }
        case (VersionConstraint)`^<ExactVersionConstraint evc>`: {
            return caratConstraint(parseExactVersionConstraint(evc));
        }
        case (VersionConstraint)`\><ExactVersionConstraint evc>`: {
            return gtConstraint(parseExactVersionConstraint(evc));
        }
        case (VersionConstraint)`\>=<ExactVersionConstraint evc>`: {
            return gtEqConstraint(parseExactVersionConstraint(evc));
        }
        case (VersionConstraint)`\<<ExactVersionConstraint evc>`: {
            return ltConstraint(parseExactVersionConstraint(evc));
        }
        case (VersionConstraint)`\<=<ExactVersionConstraint evc>`: {
            return ltEqConstraint(parseExactVersionConstraint(evc));
        }
        case (VersionConstraint)`!=<ExactVersionConstraint evc>`: {
            return neqConstraint(parseExactVersionConstraint(evc));
        }
        case (VersionConstraint)`<BranchConstraint bc>`: {
            return branchConstraint("<bc>");
        }
        case (VersionConstraint)`<WildcardConstraint wc>`: {
            return parseWildcardConstraint(wc);
        }
        case (VersionConstraint)`<ExactVersionConstraint evc>`: {
            return parseExactVersionConstraint(evc);
        }
        case (VersionConstraint)`<VersionConstraint vc1> <VersionConstraint vc2>` : {
            return andConstraint(parseConstraint(vc1), parseConstraint(vc2));
        }
        case (VersionConstraint)`<VersionConstraint vc1>, <VersionConstraint vc2>` : {
            return andConstraint(parseConstraint(vc1), parseConstraint(vc2));
        }
        case (VersionConstraint)`<VersionConstraint vc1> | <VersionConstraint vc2>` : {
            return orConstraint(parseConstraint(vc1), parseConstraint(vc2));
        }
        case (VersionConstraint)`<VersionConstraint vc1> || <VersionConstraint vc2>` : {
            return orConstraint(parseConstraint(vc1), parseConstraint(vc2));
        }
        case (VersionConstraint)`<VersionConstraint vc1> - <VersionConstraint vc2>` : {
            return hyphenConstraint(parseConstraint(vc1), parseConstraint(vc2));
        }

        default: {
            return rawConstraint("<vc>");        
        }
    }
}