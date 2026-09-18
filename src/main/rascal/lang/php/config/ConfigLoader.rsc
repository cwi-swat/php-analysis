@license{
Copyright (c) 2013, NWO-I Centrum Wiskunde & Informatica (CWI), Mark Hills, Appalachian State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
module lang::php::config::ConfigLoader

import lang::yaml::Model;
import Exception;
import Type;
import Set;
import IO;
import String;

data Exception 
    = yamlLoadException(str message, value v);

// Handle tagged and untagged scalars
private value yaml2value(scalar(int iv, \tag = t)) = iv when #int == t;
private value yaml2value(scalar(str sv, \tag = t)) = sv when #str == t;
private value yaml2value(scalar(real rv, \tag = t)) = rv when #real == t;
private value yaml2value(scalar(bool bv, \tag = t)) = bv when #bool == t;
private value yaml2value(scalar(datetime dv, \tag = t)) = dv when #datetime == t;
private value yaml2value(scalar(loc lv, \tag = t)) = lv when #loc == t;
private value yaml2value(s:scalar(value v)) = v when !(s.\tag)?;

// Handle maps
// TODO: We assume this isn't tagged. If we can have a tag at this level, revisit this.
private value yaml2value(mapping(m)) = ( yaml2value(k) : yaml2value(m[k]) | k <- m );

// Handle sequences
// TODO: We assume this isn't tagged. If we can have a tag at this level, revisit this.
private value yaml2value(sequence(l)) = [ yaml2value(v) | v <- l ];

// Handle references
// TODO: Currently, we just throw an exception
private value yaml2value(v:reference()) { throw yamlLoadException("References are currently ignored", v); }

public &T yaml2config(type[&T] configType, Node y) {
    set[str] yamlErrors = checkYAML(y);
    if (size(yamlErrors) > 0) {
        throw yamlLoadException("Errors in input YAML", yamlErrors);
    }

    yv = yaml2value(y);
    return node2value(configType, yv);
}

private str cleanName(str n) = toUpperCase(replaceAll(replaceAll(n,"_",""),"-",""));

private &T node2value(type[&T] t, value v) {
    // Handle trivial cases, e.g., integers with integer values
    if (&T vv := v) return vv;

    // Handle ADT cases. If this is an ADT (1), we should be matching a map (2) with
    // a single value (3) that points to a map itself (4, 5). The first map names the
    // constructor, while the map it points to has key/value pairs matching
    // the regular and provided keyword parameters. We unwind this across multiple
    // conditionals to hopefully provide better error messages on failure.
    if (def:adt(_,_) := t.symbol, grammar := t.definitions) { // 1
        if (\map(_,_) := typeOf(v)) { // 2
            if (map[value,value] mv := v, size(mv<0>) == 1) { // 3
                if (str nameToFind := getOneFrom(mv<0>)) { // 4
                    if (map[value,value] mp := mv[nameToFind]) { // 5
                        // At this point, we know we have a constructor for an ADT,
                        // so we want to find the choice element in the known definitions,
                        // which holds the different constructors for this ADT.
                        if (choice(def,opts) := grammar[def]) {
                            // Find all the constructors with a matching name. We do some cleaning
                            // of the names to allow approximate matches, e.g., configInfo versus
                            // config-info.
                            optrel = { < n, c > | c:cons(label(n,_),_,_,_) <- opts, cleanName(n) == cleanName(nameToFind) };

                            // Compute all matching constructors based on the given fields. This will be
                            // based on the names of regular and keyword parameters.
                            set[Production] matchingConstructors = { };
                            for (c <- optrel<1>, cons(label(n,_),flds,kflds,_) := c) {
                                // Fields we need for this constructors
                                neededFields = { cleanName(pn) | label(pn,_) <- flds };
                                // Keyword params we may find for this constructor
                                keywordFields = { cleanName(pn) | label(pn,_) <- kflds };
                                // The actual names of fields from the YAML file
                                mapFields = { cleanName(mn) | mn <- mp<0> };

                                // We have a match if the fields in the YAML file provide
                                // all the needed fields and if any other fields from the
                                // YAML file are the names of keyword parameters
                                if (isEmpty(neededFields - mapFields)) {
                                    if (isEmpty( (mapFields - neededFields) - keywordFields)) {
                                        matchingConstructors += c;
                                    }
                                }
                            }

                            // At this time, we can only support 1 matching constructor
                            if (size(matchingConstructors) == 1, cons(label(n,_),flds,kflds,_) := getOneFrom(matchingConstructors)) {
                                // For each regular parameter, first extract the value and type, in parameter order. Then,
                                // recursively handle each value to ensure we take care of any nested conversions (e.g., values
                                // that are themselves from ADTs).
                                // TODO: This is done in 2 steps for clarity but could be simplified into a single step.
                                lrel[value,value] args = [ < mp[mn], psym > | label(pn,psym) <- flds, mn <- mp<0>, cleanName(pn) == cleanName(mn) ];
                                list[value] typedArgs = [ node2value( type(argt,grammar), argv ) | < argv, Symbol argt > <- args ];

                                // Now, do the same with the keyword parameters. These are not ordered, so we also keep
                                // the parameter names around as well as the value and type.
                                // TODO: This is done in 2 steps for clarity but could be simplified into a single step.
                                rel[str,value,value] keywordArgs = { < pn, psym, mp[mn] > | label(pn,psym) <- kflds, mn <- mp<0>, cleanName(pn) == cleanName(mn) };
                                map[str,value] typedKeywordArgs = ( pn : node2value(type(ptype,grammar),pval) | < pn, Symbol ptype, pval > <- keywordArgs );

                                // Using the computed regular and keyword params, construct an instance
                                // of this type.
                                return make(t, n, typedArgs, typedKeywordArgs );
                            } else if (isEmpty(matchingConstructors)) {
                                throw yamlLoadException("Matching constructor not found for value", v);
                            } else {
                                throw yamlLoadException("Multiple matching constructors found for value", v);
                            }
                        } else {
                            yamlLoadException("Constructor choices for ADT <def> not found in grammar", v);
                        }
                    } else {
                        yamlLoadException("The parameters for the constructor should be in a map, but a value of type <typeOf(mv[nameToFind])> was provided", v);
                    }
                } else {
                    yamlLoadException("The keys in the map should be of type str, but <getOneFrom(mv<0>)> is of type <typeOf(getOneFrom(mv<0>))>", v);
                }
            } else {
                throw yamlLoadException("For ADTs, the value should be a map with a single key with the same name as the constructor", v);
            }
        } else {
            throw yamlLoadException("For ADTs, the matching value should be a map, not a <typeOf(v)>", v);
        }
    } else if (\loc() := t.symbol && str sval := v && loc lval := toLocation(sval) && &T tval := lval) {
        // We need a special case for locations since they are given as strings
        return tval;
    } else {
        throw yamlLoadException("Encountered an unsupported type: <t.symbol>", v);
    }

    throw yamlLoadException("Could not match with a constructor", v);
}
