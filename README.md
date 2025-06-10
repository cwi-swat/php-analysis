Introduction
------------

This repository contains our ongoing work on PHP Analysis in Rascal
(PHP AiR).

Running Our Software
--------------------

The main prerequisites to running the [PHP][php], [Java][java], and [Rascal][rascal] code
used to implement our analysis are:

* Java JDK version 17: Java 11 is available from the [Java download][java] page. We recommend using the Eclipse Temurin release to avoid any licensing issues.
* PHP version 8: Although you can download the sourcecode for PHP from the [PHP download][php] page, it's often easier to use a precompiled version. For macOS, you can use [Homebrew][homebrew] and the [Homebrew PHP Formula][homebrew-php] to easily install a working version of PHP. For Windows, [XAMPP][xampp] provides a working version of PHP. For Linux, you should be able to use your package manager to install the newest version. Note that PHP no longer is included on macOS with the developer tools.

To edit and run Rascal code, please see the relevant information in the [online Rascal documentation][run-rascal]. You can use the command line, Eclipse, or VScode (recommended). All included code should work with the newest release of Rascal. 

To parse PHP code, we are using a fork of an open-source PHP
Parser. This is also available in our Github repository, and
is named [PHP-Parser][phpp]. You will want to clone this project to a convenient location.

[java]: https://adoptium.net/temurin/releases/?version=17
[rascal]: http://www.rascal-mpl.org
[php]: http://www.php.net/downloads.php
[phpp]: https://github.com/cwi-swat/PHP-Parser
[issta2013]: https://cs.appstate.edu/hillsma/publications/hills-klint-vinju-2013-issta.pdf
[homebrew]: https://brew.sh/
[homebrew-php]: https://formulae.brew.sh/formula/php
[xampp]: https://www.apachefriends.org/
[run-rascal]: https://www.rascal-mpl.org/docs/GettingStarted/RunningRascal/
[fe-repo]: https://github.com/PLSE-Lab/feature-evolution

Using PHP AiR Directly
----------------------

The PHP AiR code can be used directly, without creating another project. For instance, if you are trying to build a new analysis for PHP, and would like that to be incorporated directly into PHP AiR, it would make the most sense to add the analysis directly into this project. To do so, you can open/run the code in this project directly, e.g., by opening the project in VScode and running the code using a Rascal terminal. You will want to configure PHP AiR as described below, so it knows where to find the systems being analyzed and the PHP parser.

Using PHP AiR as a Maven Dependency
-----------------------------------

You can also use PHP AiR as a Maven dependency. This is the best alternative if you are creating a tool or analysis that will be kept separate from PHP AiR (that will evolve on its own, outside of the main PHP AiR project). An example is [this work on feature evolution][fe-repo]. To do this, you will want to [create a new Rascal project](https://www.rascal-mpl.org/docs/GettingStarted/CreateNewProject/), and then add the needed dependency for PHP AiR. This is done in two places. First, in META-INF/RASCAL.MF, you will want to add the PHP AiR project as a required library. An example of this is in the feature evolution work mentioned above:

```
Project-Name: feature-evolution
Source: src/main/rascal
Require-Libraries: |lib://php-analysis|
```

Second, you will want to add PHP AiR as a plugin dependency in the pom.xml file. This looks like the following:

```
<dependency>
    <groupId>org.rascalmpl</groupId>
    <artifactId>php-analysis</artifactId>
    <version>0.3.1</version>
</dependency>
```

The `version` will depend on whether you also have PHP AiR installed locally. If you are also making changes to the PHP AiR project, you will want to use the version from the `pom.xml` file in that project. If not, you should select a version available to download as a dependency.

You will now be able to import libraries from PHP AiR in your project and in a Rascal console created in the context of your project.

Configuring PHP AiR
-------------------

Before you first use PHP AiR, you need to set the values of configuration variables in a YAML file and set the environment variable `PHP_AIR_CONFIG` to point to this file. For instance, to set this to a file named `config.yaml` in a folder under your home directory named `/Projects/php-analysis/php-analysis`, you would use command `export PHP_AIR_CONFIG=$HOME/Projects/php-analysis/php-analysis/config.yaml`. You can also set this when using the `code` command to start VSCode, like `PHP_AIR_CONFIG=$HOME/Projects/php-analysis/php-analysis/config.yaml code .` to launch VSCode in the directory of the PHP AiR project.

An example of this configuration file, based on one used by one of the contributors to this project, is shown below. This file is also included in the root of the repository. Note that we assume, for this README, that all code being analyzed, and all intermediate results, are stored in a directory named `PHPAnalysis` in the user's home directory (i.e., `~/PHPAnalysis` on a Mac or Linux machine). 

```
# Main PHP Analysis configuration settings.
php-air:
  # The location of the PHP executable in Rascal location format.
  phpLoc: "file:///opt/homebrew/bin/php"
  # The debugging level for log statements.
  # 0 means disable logging
  # 1 means typical logging statements
  # 2 means debug-level logging
  logLevel: 2
  # The location of the cloc tool, used for source lines of code,
  # in Rascal location format.
  clocLoc: "file:///opt/homebrew/bin/cloc"

# Settings related to parsing PHP code.
parsing:
  # Indicates whether to use the parser contained in a distributed jar 
  # file or from the directory given as parserLoc. By default, this should
  # be false unless you have such a file (e.g., a Java-based parsing library
  # for PHP).
  usePhpParserJar: false
  # The base install location for the PHP-Parser project, in Rascal location format.
  parserLoc: "file:///Users/hillsma/Projects/php-analysis/PHP-Parser"
  # The memory limit for PHP when the parser is run. This may need to
  # be increased if the parser runs out of memory, e.g., because of an
  # especially large or deeply-nested script.
  parserMemLimit: "1024M"
  # The name of the AST to Rascal conversion script. This should not be
  # modified unless you have created your own version of this.
  astToRascal: "AST2Rascal.php"
  # The working directory for when the parser runs, in Rascal location format.
  parserWorkingDir: "file:///Users/hillsma/Projects/php-analysis/PHP-Parser"

# Analysis-related settings.
analysis:
  # The base location for the corpus and any serialized files, in Rascal
  # location format. You would normally put code to analyze under this folder,
  # but this isn't required. Any serialized data will be stored under this folder.
  baseLoc: "home:///PHPAnalysis"
  # The base install location for the php-analysis project. This is only
  # needed if you are working directly on the project, versus using it as
  # a dependency, since this is needed to run tests. This is given in
  # Rascal location format.
  analysisLoc: "file:///Users/hillsma/Projects/php-analysis/php-analysis/"
  # Where to put the binary representations of parsed systems, in Rascal 
  # location format.
  parsedDir: "home:///PHPAnalysis/serialized/parsed"
  # Where to put the binary representations of extracted statistics, in
  # Rascal location format.
  statsDir: "home:///PHPAnalysis/serialized/stats"
  # Where to put extracted counts (e.g., SLOC), in Rascal location format.
  countsDir: "home:///PHPAnalysis/serialized/counts"
  # Where the PHP sources for the corpus reside. This is for systems given
  # with each system version in a separate directory. This is in Rascal
  # location format.
  corpusRoot: "home:///PHPAnalysis/systems"
  # This should only ever be true if we don't have source, i.e., we only have the
  # extracted binaries for parsed systems. This should normally be false.
  useBinaries: false
```

The configurable values in this file are as follows:

* `phploc` points to the location of the php binary
* `logLevel` indicates how much debugging information will be seen, and can be set to
  0 to turn output of this information off
* `clocLoc` is the location of the `cloc` tool, which is used to compute metrics about source code
* `usePhpParserJar` should generally be `false`, and is mainly present for historical reasons
* `parserLoc` points to the location of the PHP-Parser project
* `parserMemoryLimit` gives the memory limit value to pass to PHP, and can be increased if the parser is running out of memory
* `astToRascal` should not be changed unless a file other than `AST2Rascal.php` is being used to build Rascal ASTs
* `parserWorkingDir` points to the location of the working directory for when the parser runs
* `baseLoc` provides the base location for a number of files created as part of
  the parsing and extraction process, including the directory where parsed
  files are stored and the root of the corpus; the remaining directories are
  subdirectories of this
* `analysisLoc` points to the location of the php-analysis project itself
* `parsedDir` indicates where serialized versions of parsed PHP systems should be stored
* `statsDir` contains computed stats for PHP systems
* `countsDir` contains computed counts for PHP systems
* `corpusRoot` is the location of the systems under analysis; systems do not need to be stored there, but this allows 
  some of the built-in functionality for counting, finding, and parsing systems to be used
* `useBinaries` should generally be `false`, and is only needed when you have the serialized parse trees but no longer have access
  to the source code you want to analyze

To check to ensure that the directories are properly set up, you can run the following:

    import lang::php::util::Utils;
    checkConfiguration();

This will run several checks to make sure the directories can be found and that the parser
can parse a simple PHP expression. 

Parsing Older Code
------------------

We currently support PHP code up to version 8, including new features such
as nullable annotations on types and property hooks. Because of the evolution of the language,
some older code does not parse, though, which means those scripts will be
represented as a special type of _error script_ using the `errscript`
`Script` constructor. The main issues we are aware of are the following:

* Code in PHP version 4 often captured a reference to created objects, e.g., 
(from phpBB version 3.0.9) `$instance =& new phpbb_captcha_qa();`. Starting
in PHP 5, new objects are automatically treated as references, so this syntax
(using `&` to capture the reference) was deprecated, and is now no longer
supported.

* Some early PHP code, like early versions of MediaWiki, use `namespace` as
an identifier. This is now a keyword to declare a namespace in PHP.

* Some PHP code used `match` or `MATCH` as names, which is no longer supported
with the addition of the `match` expression.

If we find other common issues we will add them here.

Reorganization
--------------

This code is currently being reorganized to make it easier to use as a
dependency in your own PHP analysis projects. Because of this, we are
moving earlier experiments into their own projects. Links to those
projects will be added soon. They can be helpful if you are trying to
figure out how to do something similar to what we have done in the past.
