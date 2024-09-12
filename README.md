Introduction
------------

This repository contains our ongoing work on PHP Analysis in Rascal
(PHP AiR).

Running Our Software
--------------------

The main prerequisites to running the [PHP][php], [Java][java], and [Rascal][rascal] code
used to implement our analysis are:

* Java JDK version 11: Java 11 is available from the [Java download][java] page. We recommend using the Eclipse Temurin release to avoid any licensing issues.
* PHP version 8: Although you can download the sourcecode for PHP from the [PHP download][php] page, it's often easier to use a precompiled version. For macOS, you can use [Homebrew][homebrew] and the [Homebrew PHP Formula][homebrew-php] to easily install a working version of PHP. For Windows, [XAMPP][xampp] provides a working version of PHP. For Linux, you should be able to use your package manager to install the newest version. Note that PHP no longer is included on macOS with the developer tools.

To edit and run Rascal code, please see the relevant information in the [online Rascal documentation][run-rascal]. You can use the command line, Eclipse, or VScode. All included code should work with the newest release of Rascal. 

To parse PHP code, we are using a fork of an open-source PHP
Parser. This is also available in our Github repository, and
is named [PHP-Parser][phpp]. You will want to clone this project to a convenient location.

[java]: https://adoptium.net/temurin/releases/?version=11
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
    <version>0.2.1-SNAPSHOT</version>
</dependency>
```

You will now be able to import libraries from PHP AiR in your project and in a Rascal console created in the context of your project.

Configuring PHP AiR
-------------------

Before you first use PHP AiR, you need to create a file named Config.rsc that will be in the folder src/main/rascal/lang/php/config. This will be the module `lang::php::config::Config`. You will do this either directly in the PHP AiR project or within your own project that imports PHP AiR as a dependency. 

An example of this configuration file is shown below. Note that we assume, for this README, that all code being analyzed, and all intermediate results, are stored in a directory named `PHPAnalysis` in the user's home directory (i.e., `~/PHPAnalysis` on a Mac or Linux machine). Note also that there is an existing file under src/main/rascal/lang/php.config.rsc-dist. This file contains a template that you can copy to create your config file, and is the easiest way to create a new one. This file also contains Rascal `@doc` comments for each item. These comments are not shown below.

```
module lang::php::config::Config

public bool usePhpParserJar = false;

public loc phploc = |file:///usr/local/php5/bin/php|;

public loc parserLoc = |file:///Users/hillsma/Projects/phpsa/PHP-Parser|;

public loc analysisLoc = |file:///Users/hillsma/Projects/phpsa/rascal/php-analysis/|;

public str parserMemLimit = "1024M";

public str astToRascal = "lib/Rascal/AST2Rascal.php";

public loc parserWorkingDir = (parserLoc + astToRascal).parent;

public loc baseLoc = |home:///PHPAnalysis|;

public loc parsedDir = baseLoc + "serialized/parsed";

public loc statsDir = baseLoc + "serialized/stats";

public loc corpusRoot = baseLoc + "systems";

public loc countsDir = baseLoc + "serialized/counts";

public bool useBinaries = false;

public bool includePhpDocs = false;
public bool includeLocationInfo = false;
public bool resolveNamespaces = false;

public int logLevel = 2;
```

The configurable values in this file are as follows:

* phploc, of type `loc`, points to the location of the php binary
* parserLoc, of type `loc`,  points to the location of the PHP-Parser project
* analysisLoc, of type `loc`,  points to the location of the php-analysis project itself
* astToRascal, of type `str`, points to the location of file AST2Rascal.php inside PHP-Parser
* parserWorkingDir, of type `loc`, points to the location of the working directory for when the parser runs
* baseLoc, of type `loc`,  provides the base location for a number of files created as part of
  the parsing and extraction process, including the directory where parsed
  files are stored and the root of the corpus; the remaining directories are
  subdirectories of this
* logLevel indicates how much debugging information will be seen, and can be set to
  0 to turn output of this information off
  
Make sure that `useBinaries` is false; this should only be true in cases where you
have the binaries built and no longer have the source. Due to some recent changes, this may not work correctly in all cases.

To check to ensure that the directories are properly set up, you can run the following:

    import lang::php::util::Utils;
    checkConfiguration();

This will run several checks to make sure the directories can be found and that the parser
can parse a simple PHP expression. 

Parsing Older Code
------------------

We currently support PHP code up to version 8, including new features such
as nullable annotations on types. Because of the evolution of the language,
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
