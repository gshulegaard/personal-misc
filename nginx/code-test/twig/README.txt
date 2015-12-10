ThoughtWorks Coding Test - Problem 1

USAGE::  from digraph import DiGraph

TEST:    python test_digraph.py -v

Optional, interactive (shell, command) usage::
         python digraph_cli.py --help (to print usage info)
         python digraph_cli.py <command> -f <graph_filename>
         python digraph_cli.py <command> -q -f <graph_filename>
         python digraph_cli.py num_routes for CC where stops lt 3 cyclic -f prob1.twef

EXAMPLES (as shell commands with output and via requirement numbering):

1a)  python digraph_cli.py route distance for ABC -q -f examples/prob1.twef
     9
1b)  python digraph_cli.py route distance for ABC -f examples/prob1.twef
     Route ABC distance is 9
2)   python digraph_cli.py route distance for AD -q -f examples/prob1.twef
     5
3)   python digraph_cli.py route distance for ADC -qf examples/prob1.twef
     13
4)   python digraph_cli.py route distance for AEBCD -qf examples/prob1.twef
     22
5)   python digraph_cli.py route distance for AED -qf examples/prob1.twef
     NO SUCH ROUTE
6a)  python digraph_cli.py num_routes for CC where stops lt 3 cyclic -qf examples/prob1.twef
     2
6b)  python digraph_cli.py num_routes for CC where stops lt 3 cyclic -f examples/prob1.twef
     Num-routes-for CC where stops lt 3 cyclic = 2.  ['CEBC', 'CDC']
7a)  python digraph_cli.py num_routes for AC where stops eq 3 cyclic -qf examples/prob1.twef
     3
7b)  python digraph_cli.py num_routes for AC where stops eq 3 cyclic -f examples/prob1.twef
     Num-routes-for AC where stops eq 3 cyclic = 3.  ['ABCDC', 'ADCDC', 'ADEBC']  
8a)  python digraph_cli.py route shortest for AC -qf examples/prob1.twef
     9
8b)  python digraph_cli.py route shortest for AC -f examples/prob1.twef
     Shortest distance for AC is 9:  ABC
9a)  python digraph_cli.py route shortest for BB -qf examples/prob1.twef
     9
9b)  python digraph_cli.py route shortest for BB -f examples/prob1.twef
     Shortest distance for BB is 9:  BCEB
10a) python digraph_cli.py num_routes for CC where distance lt 30 cyclic -qf examples/prob1.twef
     7
10b) python digraph_cli.py num_routes for CC where distance lt 30 cyclic -f examples/prob1.twef 
     Num-routes-for CC where distance lt 30 cyclic = 7.  ['CEBC', 'CEBCEBC', 'CEBCEBCEBC', 'CEBCDC', 'CDC', 'CDCEBC', 'CDEBC']     

===  Future Directions (FDs)   ===

FD::  Conform digraph.py to whatever coding stds/conventions apply

      ThoughtWorks asks for production quality code.  For now,
      some in-line breadcrumbs (aka comments) will be left
      for downstream maintainers in a largely ad-hoc fashion.      

FD::  Use NetworkX/etc. vs. re-invention of a class graph (sigh)

      ThoughtWorks (TW) requires that Python standard graph
      classes be avoided for the purposes of this coding test.
      Thus, there is no use of pseudo-standard, pythonic
      resources like NetworkX.  To upgrade this code to
      production quality, it would be better to employ some
      real-world, battle-tested libraries/packages like
      NetworkX (see http://networkx.github.io) or, less likely,
      something else (like PyGraph,
      see http://code.google.com/p/python-graph).

FD::  Add a Graph (abstract?) base class, etc.

      Given that this reinvents a wheel (for a coding test),
      no effort has been made to fashion a truly production-grade
      suite of graph-related classes.  This isn't meant to
      be yet-antoher graph manipulation package/module.  

FD::  Add (support for) node annotatations

      A simple lookup/symbol table of node annotations, via
      a correlated (and co-maintained) dictionary, seems like
      an obvious omission here.  Vertex identifier values
      should be shared between graph.__graph_dict and this
      pututative, future, correlated dictionary (of vertex
      annotations with class DiGraph).
      
      Node annotions are supported (already) by most of
      the general-purpose graph handling 
      libraries/packages (e.g. NetworkX, PyGraph, etc.)

FD::  Add (optional) interactive shell.  Upgrade from CLI-only

      As ThoughtWorks (TW) advises, this coding test must
      avoid the use of non-standard-library imports/facilities,
      so no (reinvent-the-wheel) effort will be made to layer
      in facilities for wrapping the included (but optional) CLI
      with an (also optional) interactive shell
      (e.g. no 'import cmd' or whatever).

      For now, we'll stick with the uber-simple (and lame)
      parsing of the 'command' (via some argparser and then some crude,
      keyword-based, cmd_*() function dispatch).  This quick-and-dirty
      hackery is stuff in at the bottom (just for the convenience of
      reviewers).  This detritus is meant to assist with the review of
      class DiGraph.  This reviewer-convenience scaffolding is **NOT**
      meant to be 'production quality' (as per ThoughtWorks requirement).

FD::  Integrate some appropriate/production-std. Exception hierarchy

      Presumably some Exception heirarchy exists in the larger
      production (product/product-line) environment.  I have a hard
      time imagining this singular graph-related class (DiGraph)
      being used as a general purpose class/package.  
        
      In the meantime (and for the most part), this module/package
      will fall back to using old-fashion method/function return codes
      (which follow the venerable Unix/Linux exit-code
      convention ... where zero/FALSE indicates success).

      Given that the broader 'produdction/product/org' context
      details are missing, this antiguated approach to
      error/exception handling is hardly production quality.
      Thus, I've added this future direction (FD) note.
      Maybe this should be addressed sooner than later. I'm
      hazarding a guess that it doesn't much matter (here).

FD::  Maybe add multigraph/psuedograph support?  Or not ...

      A Class DiGraph object has zero or one edge
      between any pair of vertices.  Class
      Digraph cannot represent a multigraph (or psuedograph).
      See http://en.wikipedia.org/wiki/Multigraph.

      For starters, and with comment, the ThoughtWorks Coding
      Test (problem #1) poses a singular DiGraph.  If this were
      'production quality', some thought would be given to
      downstream/roadmap requirements that might or might
      not raise the specter of multigraph support.  For now,
      the YAGNI principle applies ('You Aren't Going to Need It').

      By embracing the no-multigraph limitation, class DiGraph
      is free to employ three-levels of nested, dictionaries
      (aka assocative maps).  Besides, when it comes to multi-graphs (and
      even more so than hypergraphs) ... Thar be dragons that way!

FD::  Convert this README to reStructuredText (*.rst)

      Since Python is not one of the languages often used 
      for ThoughtWorks Coding tests, plain 
      text might be more convenient (here).  On the other 
      hand, production-quality Python code should 
      employ a richer README markup convention. 

FD::  Add docs (probably via Sphinx - and a makefile)

      For now, the 'doc' directory is just an empty 
      placeholder.

FD::  Improve test coverage - drastically

      Aside from the test cases specified by ThoughtWorks (TW) 
      for coding test problem #1 (which I used for test-driven 
      development - TDD), I just ran out of motivation.  
      This lapse does **NOT** to imply that 'production-quality'
      code can get by with such paltry and perfunctory 
      (TDD-only) test coverage.  Typically, a tests directory 
      would appear with more code than the package itself.  
      Typically, the 'src' would be in a subdirectory 
      eponymously named for the project (i.e. twig/twig - 
      where TWIG -->  ThooughtWorks Interactive Graph)
