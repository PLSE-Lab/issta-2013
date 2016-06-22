Introduction
------------

This repository contains the code used to run the experiments in the paper
[An Empirical Study of PHP Feature Usage: A Static Analysis Perspective][ISSTA-paper]
by [Mark Hills][mh], [Paul Klint][pk], and [Jurgen J. Vinju][jv] that
appeared in [ISSTA 2013][ISSTA-2013]. This code makes use of the
[PHP AiR][PAiR] system, a PHP analysis framework written using the
[Rascal][Rascal] meta-programming language. Please see the page for
[PHP AiR][PAiR] for instructions on downloading and configuring the framework,
which is required to use the code here.

[mh]: http://www.cs.ecu.edu/hillsma
[pk]: http://homepages.cwi.nl/~paulk/
[jv]: http://homepages.cwi.nl/~jurgenv/
[ISSTA-paper]: http://www.cs.ecu.edu/hillsma/publications/php-feature-usage.pdf
[ISSTA-2013]: http://issta2013.inf.usi.ch/
[PAiR]: https://github.com/cwi-swat/php-analysis
[Rascal]: http://www.rascal-mpl.org/

Setup
-----

PHP AiR and this code are both provided as Eclipse projects, and both should
be run in the same Eclipse workspace. The [corpus][issta-corpus] used in the
paper should be downloaded and installed into the `PHPAnalysis` directory.
Assuming that `wget` is installed and this directory is in your home directory,
the following will get and unzip the corpus:
    
    cd ~/PHPAnalysis
    wget http://www.cs.ecu.edu/hillsma/experiments/corpus-icse13.tgz
    tar -xpzvf corpus-icse13.tgz

Note that there are some differences in the results you will get using this
corpus and using the versions of each system that can be retrieved from
GitHub. This is because some of the downloads for the systems (which is what
we assume that people will use) include some additional libraries or extra
functionality that are not directly in the repositories for each system.

[issta-corpus]: http://www.cs.ecu.edu/hillsma/experiments/corpus-icse13.tgz

Generating the Figures and Tables
---------------------------------

A function is provided to generate each of the figures and tables given in the
paper except for those figures showing code snippets. Running each of these
functions will return the LaTeX generating the figure or table shown in the
paper.

How the Information is Computed
-------------------------------

More details will be provided soon. At this point, the easiest way to understand
the computations is to walk through the functions called to generate each figure
or table.