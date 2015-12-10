# !/usr/bin/env python
# -*- coding: utf-8 -*-
# FD::  Sometimes, corporate/legal boilerplate goes here.  TBD.
#       By the way, FD means '(Plausible) Future Direction'

import os, sys, logging, datetime
from   digraph import DiGraph

def cmd_route(args, graph):
  return_code = False # Presume success until/unless something goes amiss
  if args.iquery.lower() == 'distance':
    if cmd_route_distance(args, graph):
      return_code = True
  elif args.iquery.lower() == 'shortest':
    if cmd_route_shortest(args, graph):
      return_code = True
  else:
    logging.error("Unrecognized route query = %s", args.iquery.lower())
    return_code = True
  return return_code

def cmd_route_distance(args, graph):
  return_code = False
  if args.iprose[0].lower() == 'for': 
    route = args.iprose[1]  # vertex id vals are case-sensitive.  Do not lower()
    if not route.isalpha():
      print "Route-distance command syntax expects a route of letters only: {1}".format(route)
      logging.error("Route-distance command syntax expects route of letters only: \'%s\'",
                    route)
      return_code = True
    if len(args.iprose) > 2:  
      print "Ignoring extra prose following a route-distance command: {0]}".format(str(args.iprose[2:]).lower())
      logging.warn("Route-distance command ignoring the following extra prose:  \'%s\'",
                   str(args.iprose[2:]).lower())      
      return_code = False # Just reiterating that extra-prose is OK ;-)
  else:
    logging.error("Route-distance command syntax expects keyword \`%s\`, finds \'%s\'",
                  'for', args.iprose[0].lower())
    print "Route-distance command missing the \'for\' keyword"
    return_code = True
  if return_code: # if the route command is malformed, bail out
    return return_code
  result = graph.distance(route)
  if result < 0:
    print 'NO SUCH ROUTE'
  else:
    if args.quiet:
      print result
    else:
      print "Route {0} distance is {1}".format(route, result)
  return return_code

def cmd_route_shortest(args, graph):
  return_code = False
  if args.iprose[0].lower() == 'for': # Move to check the route field
    route = args.iprose[1] # vertex identifer values are case-sensitive
    if not route.isalpha():
      print "Route-shortest command syntax expects route w/letters only: {1}".format(route)
      logging.error("Route-shortest command syntax expects route w/letters: \'%s\'",
                    route)
      return_code = True
    if len(args.iprose) > 2:  
      print "Route-shortest command ignoring the following extra prose: {0]}".format(str(args.iprose[2:]).lower())
      logging.warn("Route-shortest command ignoring this following extra prose:  \'%s\'",
                   str(args.iprose[2:]).lower())      
      return_code = False # Just to reiterate that extra-prose is OK ;-)
  else:
    logging.error("Route-shortest command syntax expects keyword \`%s\`, finds \'%s\'",
                  'for', args.iprose[0].lower())
    print "Route-shortest command missing \'for\' keyword"
    return_code = True
  if return_code: # if the route command is malformed, bail out
    return return_code
  (result, distance, found_route) = graph.get_shortest_distance(route[0], route[1])
  if result < 0:
    print 'NO SUCH ROUTE'
  else:
    if args.quiet:
      print distance
    else:
      print "Shortest distance for {0} is {1}:  {2}".format(route, distance, found_route)
  return return_code
    
def cmd_num_routes(args, graph):
  return_code = False # Presume success until/unless something goes amiss
  if args.iquery.lower() == 'for':
    if cmd_num_routes_for(args, graph):
      return_code = True
  else:
    logging.error("Unrecognized num_routes query:  %s", args.iquery.lower())
    return_code = True
  return return_code

def cmd_num_routes_for(args, graph):
  return_code = False
  route = args.iprose[0] # vertex identifer values are case-sensitive
  if not route.isalpha():
    print "Num-routes-for command syntax error:  {0}".format(route)
    logging.error("%s command syntax expects a start/end (two-part) route, but finds \'%s\'",
                  'Num-routes-for', route)
    return_code = True
  if len(route) > 2:
    print "Too many steps in a num_routes_for route:  {0}".format(route)
    logging.error("%s expects only a two-part (start-and-end) route, but finds \'%s\'",
                  'Num-routes-for', route)
    return_code = True
  if len(args.iprose) < 4:
    print "A num-routes-for command must supply a route-attribute-predicate (RAP)"
    print "RAP syntax:  where <attr> <relop> <numeric_value>"
    print "attr (regexp) syntax: [ distance | steps | stops ] "
    print "relop in {0}".format(graph.relops())
    print "The RAP on the command line is too short: {0}".format(str(args.iprose[1:]).lower())
    logging.error("Num-routes-for command RAP is found to be too short:  %s",
                  args.iprose[1:])
    return_code = True
  if return_code:
     return return_code # Bail out or proceed with yet more ad-hoc syntax analysis
  if not args.iprose[1].lower() == 'where':
    print "Num-routes-for command missing keyword \'where\'"
    logging.error("Num-routes-for command missing keyword \'where\'")
    return_code = True
  if not (args.iprose[2].lower() == 'distance' \
          or args.iprose[2].lower() == 'steps' \
          or args.iprose[2].lower() == 'stops'):
    print "Num-routes-for command missing keyword: \'distance\', \'steps\' or \'stops\'"
    logging.error("Num-routes-for command missing keyword [\'distance\', \'steps\' \'stops\']")
    logging.error("Num-routes-for command has this instead: %s", args.iprose[2].lower())
    return_code = True
  if not args.iprose[3].lower() in graph.relops():
    print "Num-routes-for command has an invalid relop:  {0}".format(args.iprose[3].lower())
    logging.error("Num-routes-for command uses invalid relop:  %s",
                  args.iprose[3].lower())
    return_code = True
  if not args.iprose[4].isdigit():
    print "Num-routes-for command has an invalid numeric value:  {0}".format(args.iprose[4].lower())
    logging.error("Num-routes-for command has invalid numeric value:  %s",
                  args.iprose[4])
    return_code = True
  route_type = 'acyclic'  # acyclic is the default
  if len(args.iprose) > 5:
    if not args.iprose[5].lower() in graph.route_types():
      print "Num-routes-for command suffix must in {0}.  Found {1}".format(
        graph.route_types, args.iprose[5].lower())
      logging.warn("Invalid num-routes-for command suffix:  %s.  Defaulting to %s",
                   args.iprose[5].lower(), route_type)
      return_code = True
    else:
      route_type = args.iprose[5].lower()
  if return_code:
    return return_code # Bail out or proceed with more (lame/tedious) ad-hoc syntax analysis
  if len(args.iprose) > 6:
    print "Ignoring extra prose following a num-routes-for command: {0]}".format(str(args.iprose[5:]).lower())
    logging.warn("Ignoring %s command with the following extra prose:  \`%s\'",
                 'Num-routes-for', str(args.iprose[6:]).lower())      
    return_code = False # Just to reiterate that this extra-prose is OK ;-)
  (result, routes) = graph.get_routes(route,
                                      route_type,
                                      args.iprose[2].lower(),
                                      args.iprose[3].lower(),
                                      args.iprose[4])
  if result < 0:
    print 'ERROR'
  elif result == 0 and len(routes) == 0: 
    print 'NO SUCH ROUTE'
  elif result > 0:
    print "Bad result value returned:  {0}".format(result)
  else:
    if args.quiet:
      print len(routes)
    else:
      print "Num-routes-for {0} where {1} {2} {3} {4} = {5}.  {6}".format(
        route,
        args.iprose[2].lower(),
        args.iprose[3].lower(),
        args.iprose[4],
        route_type,
        len(routes), routes)
      
def main(args):
  """ ThoughtWorks Interactive Graph (TWIG) Command Line Interface (CLI) """
  # Initialize a log file.  This is a good habit for production-quality utilities/systems.
  if not os.path.isdir(os.path.join(os.getcwd(), '../log')):
    os.makedirs('../log')
  log_file = os.path.join(os.getcwd(), '../log', 'trace.log')
  if args.append:
    if args.debug:
      logging.basicConfig(filename=log_file,
                          level=logging.DEBUG,
                          filemode='a',
                          format='%(asctime)s-%(msecs)d %(name)s %(levelname)s %(message)s',
                          datefmt='%Y%m%d %H:%M:%S')

    else:
      logging.basicConfig(filename=log_file,
                          level=logging.WARNING,
                          filemode='a',
                          format='%(asctime)s-%(msecs)d %(name)s %(levelname)s %(message)s',
                          datefmt='%Y%m%d %H:%M:%S')
  else:
    if args.debug:
      logging.basicConfig(filename=log_file,
                          level=logging.DEBUG,
                          filemode='w',
                          format='%(asctime)s-%(msecs)d %(name)s %(levelname)s %(message)s',
                          datefmt='%Y%m%d %H:%M:%S')
    else:
      logging.basicConfig(filename=log_file,
                          level=logging.WARNING,
                          filemode='w',
                          format='%(asctime)s-%(msecs)d %(name)s %(levelname)s %(message)s',
                          datefmt='%Y%m%d %H:%M:%S')
  if args.verbose:
      logging.debug("Logging configured for %s", log_file)
      now = datetime.datetime.now()
      logging.debug("Starting ThoughtWorks coding-test-problem-1 command at %s",
                    str(now))
  # Initialize a class DiGraph object as per the CLI-supplied (TWEF-format) filename
  graph = DiGraph()
  if graph.import_twef(args.graph_filename):
    logging.debug("ABORT- graph.import_twef(%s) fails", args.graph_filename)
    return 0
  logging.debug("graph.dump():\n%s", graph.dump())
  edge_list = graph.edges()
  logging.debug("edge_list:\n%s", edge_list)
  # Delegate to the appropriate command handler (for this command line's query)
  if args.ikind.lower() == 'route':
    if not cmd_route(args, graph):
      logging.debug("cmd_route() succeeds")
    else:
      print 'Route command failed.  Something went wrong! \nConsult {0}'.format(log_file)
  elif args.ikind.lower() == 'num_routes':
    if not cmd_num_routes(args, graph):
      logging.debug("cmd_num_routes() succeeds")
    else:
      print 'Num_routes command failed.  Something went wrong! \nConsult {0}'.format(log_file)
  else:
    print 'Unrecognized command:  {0}.  No handler.  Giving up.'.format(args.ikind.lower())
  logging.debug("Logging complete for %s.  Main() is done.", log_file)
  return 0

if __name__ == '__main__':
  import argparse
  arg_parser = argparse.ArgumentParser(
    description='Solutions' )
  arg_parser.add_argument('-v', '--verbose', action='store_true',
                          dest="verbose", required=False, default=False,
                          help='Elect verbose output (esp. for logging)')
  arg_parser.add_argument('-a', '--append', action='store_true',
                          dest="append", required=False, default=False,
                          help='Append to an existing solutions.log file (if any)')
  arg_parser.add_argument('--version', action='version',
                          version='%(prog)s 0.0.1',
                          help='Show embedded version string and exit')
  arg_parser.add_argument('-d', '--debug', action='store_true',
                          dest="debug", required=False, default=False,
                          help='Request debugging mode')
  arg_parser.add_argument('-q', '--quiet', action='store_true',
                          dest="quiet", required=False, default=False,
                          help='Quiet.  Trim output (to just answer)')
  arg_parser.add_argument('-f', '--graph_filename', action='store',
                          dest="graph_filename", required=True,
                          help='Specify the file name that contains the graph in question')
  # FD::  Upgrade this quick-n-dirty hack of command line parsing scheme
  #       This cruft should last only until some more sensisble, and more
  #       pythonic, command parser might replace it
  arg_parser.add_argument('ikind',
                          choices=['route', 'num_routes'],  
                          help='The general kind of inquiry for the currently loaded graph')
  arg_parser.add_argument('iquery',
                          choices=['for', 'distance', 'shortest'],
                          help='Either route attribute requested or the filler word \"for\" when preceeded by num_routes')
  arg_parser.add_argument('iprose', metavar='prose', nargs='+',
                          help='The CLI prose that goes beyond the first, two, keywords.')
  
  # parse args 
  args = arg_parser.parse_args(sys.argv[1:])
  sys.exit(main(args))

# FD::  Conform this module to whatever coding stds/conventions might apply
#
#       ThoughtWorks asks for production quality code.  For now,
#       some in-line breadcrumbs (aka comments) will be left
#       for downstream maintainers in a largely ad-hoc fashion.      

# FD::  Add (optional) full interactive shell.  Upgrade from CLI-only
#
#       As ThoughtWorks (TW) advises, this coding test must
#       avoid the use of non-standard-library imports/facilities,
#       so no (reinvent-the-wheel) effort will be made to layer
#       in facilities for wrapping the included (but optional) CLI
#       with an (also optional) interactive shell
#       (e.g. no 'import cmd' or whatever).
#
#       For now, we'll stick with the uber-simple (and lame)
#       parsing of the 'command' (via some argparser and then some crude,
#       keyword-based, cmd_*() function dispatch).  This quick-and-dirty
#       hackery is just for the convenience of code reviewers.
#       For the most part, this meant to assist with the review
#       (and testing) of class DiGraph.  This
#       reviewer-convenience scaffolding is **NOT**
#       (necessarily) meant to be 'production quality'
#       (as per ThoughtWorks requirement).
