# -*- coding: utf-8 -*-
# FD::  Sometimes, corporate/legal boilerplate goes here.  TBD.
#       By the way, FD means '(Plausible) Future Direction'

import os, sys, logging, datetime

class DiGraph(object):
  """  Class DiGraph (directed graph w/edge annotations)

  Yet another hand-rolled (directed) graph class.  Sigh ...
  
  A dictionary of vertices is the data structure used to
  represent a directed graph (aka digraph).  Each vertex
  identifier value keyed entry maps to another, nested
  dictionary of adjacent vertices.  The adjacent vertices
  map to yet another nested dictionary of edge annotations
  (in the form of name-key-to-value pairs).
  
  By convention, and for the purposes of Class DiGraph,
  edges (from one vertex to an adjacent vertex) are directed.
  The relative position of vertices within these nested
  dictionaries capture the edge direction.

  FD::  Replace with NetworkX's class DiGraph or whatever (PyGraph?)
  
        Aside from coding tests (like this one), never
        reinvent this kind of wheel.
  """

  def __init__(self, graph_dict={}):
    """ Init graph dictionary """
    self.__graph_dict = graph_dict
    self.__relops = ['lt', 'lte', 'gt', 'gte', 'eq']
    self.__route_types = ['acyclic', 'cyclic']
    
  def add_edge(self, edge):
    """  Add an edge to the graph 

    An edge will be represented by an iterable container
    with two target-tuples (e.g. a set, tuple or list).
    Any more than two target-tuples (in the edge container)
    will be ignored (by add_edge).

    Each so-called target-tuple has two signficant
    items/fields.  Positionally, the first target-tuple
    item/field must be a vertex identifier value.  The
    second is a dictionary of annotations
    (i.e. key-name/value pairs).

    By convention, this first target-tuple's annotation
    dictionary refers to the 'starting' vertex for the
    given edge.  Eventually, this might carry any vertex
    annotations for the starting/first vertex of
    the (directed) edge.  For now, vertex annotations
    are just a future direction (FD).  For now, the first
    tuple's (annotation) dictionary is (silently) ignored. 
    
    By convention, the second target_tuple's annotation
    dictionary (for an edge) carries the edge annotation
    dictionary.  Please don't confuse these edge annotations
    with (any) vertex annotations.
    
    During add_edge(), only the first item/field of first
    target-tuple is significant.  This identifies the
    source/origin/start vertex for a given edge.
    
    The second target-tuple is more (broadly) significant.
    Here, the first item/field identifies the
    destination/termination/end vertex (for a given edge).
    The second item/field is the edge annotation dictionary.    
    """
    vertex2 = edge.pop()
    if edge:  # not a loop (i.e. not a self-cycle)
      vertex1 = edge.pop()
    else:     # a loop
      vertex1 = vertex2
    if not vertex1[0] in self.__graph_dict:
      self.__graph_dict[vertex1[0]] = {}
      self.__graph_dict[vertex1[0]][vertex2[0]] = vertex2[1].copy()
    else:
      self.__graph_dict[vertex1[0]][vertex2[0]] = vertex2[1].copy()
    if not vertex2[0] in self.__graph_dict:
      self.__graph_dict[vertex2[0]] = {}
    
  def add_vertex(self, vertex):
    """ Add vertex to graph 

    If given vertex is NOT already in 
    self.__graph_dict, then add this vertex
    to the graph dictionary, else, do
    nothing.

    Beware!  The given vertex adds to the graph
    with an empty list of outbound edges, and,
    since this is a new vertex, no other vertex
    can have an outbound edge to it (yet).
    Thus, calling this method always results in
    a new, disconnected vertex.  When possible, it
    is best to use **only** add_edge() to populate the
    graph.
    """
    if vertex not in self.__graph_dict:
      self.__graph_dict[vertex] = []

  def chk_vertices(self, route):
    """ Check that each vertex in a route exists in the graph """
    result = False # Sans some exception raise, success is return FALSE
    unknown_vertices = []
    for vertex in route:
      if vertex not in self.vertices():
        unknown_vertices.append(vertex)
        result = True
    if result:
      logging.error("Route %s includes the following unknown vertices:  %s",
                    route, unknown_vertices)
    return result
  
  def distance(self, route):
    result = -1 # Sans exception raise, invalid distance value signals error 
    if self.chk_vertices(route):
      logging.error("Invalid vertices found in route:  %s", route)
      result = -1 # Just to reiterate (and signal an error)
    else:
      result = 0
      for i, vertex in enumerate(route):
        if i < len(route) - 1:
          next_vertex = route[i+1]
          if  vertex      in self.__graph_dict \
          and next_vertex in self.__graph_dict[vertex]:          
            logging.debug("Step %d from vertex %s to %s adds %d",
                          i+1, vertex, next_vertex,
                          self.__graph_dict[vertex][next_vertex]['distance'])
            result += self.__graph_dict[vertex][next_vertex]['distance']
          else:
            logging.debug("Step %d from vertex %s to %s does not exist",
                          i+1, vertex, next_vertex)
            result = -1
            break
    return result
  
  def dump(self):
    """  Serialize and pretty-print the graph
    
    FD::  Improve the pretty printing of the graph (many options ...)
    """
    return str(self.__graph_dict)
     
  def edges(self):
    """ List edges """
    return self.__generate_edges()

  def export_twef(self, gfn):
    """ Export Graph using ThoughtWorks Edge Format (TWEF) to named file
    
    FD::  Implement this inverse of import_twef()
    """
    pass

  def find_all_routes(self, start_vertex, end_vertex, path=None):
    """ Find all non-cycling paths from start_vertex to end_vertex """
    if path is None:  # Beware of Python's mutable args!  
                      # http://docs.python-guide.org/en/latest/writing/gotchas
                      # Especially beware of recursive calls with references
                      # to mutable args (stored on heap versus in each stack frame)
      path = []
    path.append(start_vertex)
    if start_vertex not in self.__graph_dict:
      return []       # Immediately abort any recursion
    routes = []       # Clean slate (on stack frame) for each call
    for vertex in self.__graph_dict[start_vertex]:
      if len(path) > 1 and vertex == end_vertex:
        found_route = list(path) 
        found_route.append(vertex)
        new_route = ''.join(found_route)
        logging.debug("find_all_routes(); Adding new_route = %s", new_route)
        routes.append(new_route)
      elif vertex not in path: # Obviate any (graph) cycle chasing!
        extended_routes = self.find_all_routes(vertex, 
                                               end_vertex, 
                                               path)
        for r in extended_routes:  
          routes.append(r)
    path.pop()  # Beware Python's call-by-object-reference semantics with mutated args
    # http://robertheaton.com/2014/02/09/pythons-pass-by-object-reference-as-explained-by-philip-k-dick/
    return routes

  def find_all_wanders(self, start_vertex, end_vertex, attr, relop, val, path=None):
    """ Subject to a RAP, find all (possibly cycling) routes from start_vertex to end_vertex """
    if path is None:  # Beware of Python's mutable args!  
                      # http://docs.python-guide.org/en/latest/writing/gotchas
                      # Especially beware of recursive calls with argument references
                      # to mutable args (stored on heap versus in each stack frame)
      path = []
    path.append(start_vertex)
    if start_vertex not in self.__graph_dict:
      return []       # Immediately abort any recursion
    routes = []       # Clean slate (on stack frame) for each call
    for vertex in self.__graph_dict[start_vertex]:
      found_route = list(path)  
      found_route.append(vertex)
      new_route = ''.join(found_route)
      check = self.__eval_rap(new_route, attr, relop, val)
      if check == 0:
        if len(path) > 1 and vertex == end_vertex: # Grab this good route
          logging.debug("find_all_wanders(); Found good route = %s", new_route)
          routes.append(new_route)

        extended_routes = self.find_all_wanders(vertex, 
                                                end_vertex,
                                                attr, relop, val,
                                                path)
        for r in extended_routes:  
          routes.append(r)
    path.pop()  # Beware Python's call-by-object-reference semantics with mutated args
    # http://robertheaton.com/2014/02/09/pythons-pass-by-object-reference-as-explained-by-philip-k-dick/
    return routes
  
  def import_twef(self, gfn):
    """ Import ThoughWorks Edge Format (TWEF) Graph Data from a filename """
    return_code = False # Assume success until/unless something goes wrong
    temp = {}
    if os.path.exists(gfn):
      try:
        with open(gfn, "rw") as ifp:
          logging.debug("open() succeeds for file %s from %s",
                        gfn, os.path.join(os.getcwd()))
          line_count = 0
          edge_count = 0
          for line in ifp:
            line_count += 1
            fields = line.rstrip('\n').split()
            if fields[0][0] == '#':  continue
            for field in fields:
              if field[0] == '#': break
              edge_count += 1
              edge = field.rstrip('\n\t, ')
              logging.debug("Add edge %d from line %d of %s: %s",
                            edge_count, line_count,
                            gfn, edge)
              temp['distance'] = int(edge[2:])
              self.add_edge( [ (edge[0], temp.copy()), (edge[1], temp.copy()) ] )
      except EnvironmentError as e:
        logging.error("An environment error occurred: %s", e.args[0])
        logging.debug("open() fails for file %s from %s",
                      gfn, os.path.join(os.getcwd()))
        return_code = True # Something has gone wrong!
    else:
      print "Misisng graph file named " + gfn + " from " + os.path.join(os.getcwd()) 
      logging.debug("Missing graph file named %s from %s",
                    gfn, os.path.join(os.getcwd()))
      return_code = True # The file is missing, so something is wrong!
    return return_code

  def get_routes(self, route, route_type, attr, relop, val):
    """ Find the routes complying with a simple route attribute predicate

        Direct (acyclic) routes do not revisit any nodes.  Wandering
        (possibly cyclic) routes may revisit nodes up the limit of what
        the (given, mandatory) route-attribute-predicate (RAP) allows.
        As per the ThoughtWorks nomenclature, a so-called 'trip'
        is a route that may admit/includes cyclic routes.  
        
        FD::  Upgrade find_all_routes() to a HOF with a predicate argument

        Since Thoughtworks explicitly warns against 'gold plating',
        perhaps this bit of professional polish should be deferred.
        For higher-order-function (HOF) details, see:
        http://en.wikipedia.org/wiki/Higher-order_function
        http://composingprograms.com/pages/16-higher-order-functions.html.
        
        It would probably be best to retain find_all_routes() but to
        implement find_all_routes() through some underlying HOF
        (using the default, missing/NULL predicate argument).

        The idea would be to pass some lambda-or-named-function into
        find_all_routes() so that the predicate could be bound-and-evaluated
        during the (recursive) chase down paths - in the logic of
        find_all_routes().  By doing this, find_all_routes() would give up
        on inappropriate route chases earlier.  Essentially, this filters out
        undesirable paths **prior** to fully exploring the full extent of
        all such routes.  By pruning away the need for further searching,
        along undesirable paths, less computation is required. 

        For large graphs, and in some applications, this (modest)
        optimization might become significant.  Then again, these sorts of
        optimizations are were long-ago been implemented by all of the
        better, third-party, graph libraries/packages.

        Not-invented-here (NIH) syndrome:  the curse that keeps on cursing ;-)    
    """
    result = 0 # Until some apropos Exception hierarchy arises (FD),
               # a negative (<0) result value signals an error
    if self.chk_vertices(route):
      logging.error("Invalid vertices found in route:  %s", route)
      result = -1
    if len(route) > 2:
      logging.error("This route is too long.  A travel goal is just a two-vertex route:  %s", route)
      result = -1
    if not route_type in self.__route_types:
      logging.error("Unrecognized route_type: %s", route_type)
      result = -1
    if not attr in ['distance', 'steps', 'stops']:
      logging.error("Unrecognized route attribute: %s", attr)
      result = -1
    if not relop in self.relops():
      logging.error("Unrecognized route-attribute-predicate (RAP) relop: %s\nValid relops are %s",
                    attr, self.relops())
      result = -1
    if not val.isdigit():
      logging.error("Route-attribute-predicates (RAPs) accept only numeric constants: %s", val)
      result = -1
    if result == -1:
      return (result, []);  # Bail out (if any args are invalid)
    sv = route[0]     # Start vertex
    ev = route[1]     # End vertex (destination desired, when/if reachable)
    compliant_routes = []
    if route_type == 'acyclic':
      candidate_routes = self.find_all_routes(sv, ev)
      logging.debug("get_routes(); acyclic candidate_routes:  %s", candidate_routes)
      for cr in candidate_routes:
        rap_result = self.__eval_rap(cr, attr, relop, val)
        if rap_result == 0:
          compliant_routes.append(cr)
        elif rap_result < 0:
          logging.error("get_routes(acyclic); RAP evaluation error for %s using: %s %s %s",
                        cr, attr, relop, val)
          return (-1, []) # Bail out.  Abort.
    elif route_type == 'cyclic': # push down the RAP to bound a wandering search 
      if relop == 'gt' or relop == 'gte':
        logging.error("get_routes(cyclic); RAP relop %s cannot limit cycling.  Use  %s",
                      relop, ['lt', 'lte', 'eq'])
        result = -1
      elif relop == 'eq': # Coerce to 'lte' to limit wandering/cycling & filter
        candidate_routes = self.find_all_wanders(sv, ev, attr, 'lte', val)
        logging.debug("get_routes(); relop-coerced candidate_routes allowing cycles:  %s",
                      candidate_routes)
        for cr in candidate_routes:
          if attr == 'steps':
            tval = len(cr) - 1
            if tval == int(val):
              compliant_routes.append(cr)
          if attr == 'stops':
            tval = len(cr) - 2
            if tval == int(val):
              compliant_routes.append(cr)
          if attr == 'distance':
            tval = self.distance(cr)
            if tval == int(val):
              compliant_routes.append(cr)
      else:
        candidate_routes = self.find_all_wanders(sv, ev, attr, relop, val)
        logging.debug("get_routes(); candidate_routes allowing cycles:  %s", candidate_routes)
        for cr in candidate_routes:
          compliant_routes.append(cr)
    else:
      logging.error("get_routes(); fumbles when given route_type =  %s",
                    route_type) 
      return (-1, []);  # Bail out.   
    return (result, compliant_routes)

  def get_shortest_distance(self, start_vertex, end_vertex):
    """ Get the shortest (by distance) route

    FD:  Optimize via the famous Djikstra algorithm

    Also, tune with an heap-based, indexed priority queue

    See http://en.wikipedia.org/wiki/Dijkstra's_algorithm
    Of course, since the use of external libraries is verbotten (here),
    the usual use of something like PQDict is deferred (as an FD):
    http://pythonhosted.org/pqdict/intro.html#what-is-an-indexed-priority-queue    
    https://github.com/nvictus/priority-queue-dictionary/blob/master/pqdict.py
    """
    result = 0
    if start_vertex not in self.__graph_dict:
      return (-1, -1, [])
    if end_vertex not in self.__graph_dict:
      return (-1, -1, [])
    candidate_routes = []
    candidate_routes = self.find_all_routes(start_vertex, end_vertex)
    logging.debug("get_shortest_distance(); direct candidate_routes:  %s", candidate_routes)
    if len(candidate_routes) > 0:
      sr = candidate_routes[0]
      sd = self.distance(sr)
      for cr in candidate_routes:
        crd = self.distance(cr)
        if crd < sd:
          sr = cr
          sd = crd
    return (result, sd, sr)
    
  def relops(self):
    return self.__relops

  def route_types(self):
    return self.__route_types
    
  def vertices(self):
    """ List nodes/vertices """
    return list(self.__graph_dict.keys())

  def __eval_rap(self, route, attr, relop, val):
    """ Static/private method to evaluate a route-attribute predicate (RAP)

        Assumes that all arguments are elsewhere/previously validated

        FD::  Generalize RAPs and their evaluation.  Be more flexible.

        While dangerous and dubious, due to security considerations,
        Python's compile/exec facilities are one possible approach:
        http://late.am/post/2012/04/30/the-exec-statement-and-a-python-mystery
        Of course, eval() is probably more than enough:
        https://docs.python.org/2/library/functions.html#eval
        
        To better secure/constrain whatever might generalize
        this hardcoded, static/private eval_rap(), something less
        general, like relop string-keyword-to-Python-op mapping table
        might be best.  TBD.  
    """
    result = 0
    if attr == 'distance':
      if relop == 'lt':
        if self.distance(route) < int(val):
          result = 0 
        else:
          result = 1 
      elif relop == 'lte':
        if self.distance(route) <= int(val):
          result = 0 
        else:
          result = 1
      elif relop == 'gt':
        if self.distance(route) > int(val):
          result = 0 
        else:
          result = 1
      elif relop == 'gte':
        if self.distance(route) >= int(val):
          result = 0
        else:
          result = 1
      elif relop == 'eq':
        if self.distance(route) == int(val):
          result = 0
        else:
          result = 1
      else:
        logging.error("Bad relop in distance route-attribute-predicate (RAP): %s", relop)
        result = -1 # Until some exception raises, signal error with neg. return 
    elif attr == 'steps':
      num_steps = len(route) - 1
      if relop == 'lt':
        if num_steps < int(val):
          result = 0 
        else:
          result = 1
      elif relop == 'lte':
        if num_steps <= int(val):
          result = 0
        else:
          result = 1
      elif relop == 'gt':
        if num_steps > int(val):
          result = 0 
        else:
          result = 1
      elif relop == 'gte':
        if num_steps >= int(val):
          result = 0 
        else:
          result  =1
      elif relop == 'eq':
        if num_steps == int(val):
          result = 0 
        else:
          result = 1
      else:
        logging.error("Bad relop in steps route-attribute-predicate (RAP): %s", relop)
        result = -1 # Until some exception raises, signal error with neg. return 
    elif attr == 'stops':
      num_stops = len(route) - 2
      if relop == 'lt':
        if num_stops < int(val):
          result = 0 
        else:
          result = 1
      elif relop == 'lte':
        if num_stops <= int(val):
          result = 0
        else:
          result = 1
      elif relop == 'gt':
        if num_stops > int(val):
          result = 0 
        else:
          result = 1
      elif relop == 'gte':
        if num_stops >= int(val):
          result = 0 
        else:
          result  =1
      elif relop == 'eq':
        if num_stops == int(val):
          result = 0 
        else:
          result = 1
      else:
        logging.error("Bad relop in stops route-attribute-predicate (RAP): %s", relop)
        result = -1 # Until some exception raises, signal error with neg. return 
    else:
      logging.error("Unknown attr in route-attribute-predicate (RAP): %s", attr)
      result = -1 # Until some exception raises, signal error with neg. return 
    return result
  
  def __generate_edges(self):
    """ Static/private method to generate a list of all edges
    
    Represent each directed edge (in the generated list)
    as a tuple composed of three (positional) items:
      0) start vertex (identifier value)
      1) end vertex (identifier value)
      2) edge annotation dictionary
         (of named values, as keyed by name)

    For loopback edges, the start and end vertex will
    be the same.  This is just a degenerate case.
    
    This naturally generalizes into a representation of a
    route (aka path) when the list of edge tuples has 
    an arbitrary number of contiguous edge tuples.
    Edge tuples are contiguous when, for all edge tuples,
    the the end vertex (identifier value) is equivalent to 
    the start vertex (identifier value) the (positionally)
    next (in the list) edge tuple.
    
    Basically, one can navigate a route (over a DiGraph) by
    iterating, successively, across each edge in a contiguous
    (i.e. end-to-start-ordered) edge list.
    """
    edges = []
    for vertex in self.__graph_dict:
      for neighbor in self.__graph_dict[vertex]:
        # Remember, Class DiGraph excludes multigraphs/psuedographs
        # so there are no self-similar edges (between same vertices)
        edges.append((vertex, neighbor, self.__graph_dict[vertex][neighbor]['distance']))
    return edges

  def __str__(self):
    "Format edges as proscribed by ThoughtWorks (despite shortcomings)"
    # FD::  Reconsider serialization of edges.  Add delimiters to disambiguate
    result = "vertices: \n"
    for k in self.__graph_dict:
      result += str(k) + " "
    result += "\nedges: \n"
    for edge in self.generate_edges():
      result += str(edge[0]) + str(edge[1]) + str(edge[2]['distance']) + " "
    return result
