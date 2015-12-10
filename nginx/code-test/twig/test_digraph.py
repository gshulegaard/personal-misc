from digraph import DiGraph
import os, sys, logging, datetime, unittest

class TestDiGraph(unittest.TestCase):
  
  def setUp(self):
    print 'setUp w/prob1.twef'
    self.graph = DiGraph()
    if self.graph.import_twef('examples/prob1.twef'):
      assert False, "import_twef() fails"
      
  def testTrivial(self):
    self.failUnless(True)

  def testRouteDistanceABC(self):
    self.failIf(self.graph.distance('ABC') != 9)

  def testRouteDistanceAD(self):
    self.failIf(self.graph.distance('AD') != 5)

  def testRouteDistanceADC(self):
    self.failIf(self.graph.distance('ADC') != 13)

  def testRouteDistanceAEBCD(self):
    self.failIf(self.graph.distance('AEBCD') != 22)

  def testRouteDistanceAED(self):
    self.failIf(self.graph.distance('AED') >= 0)

  def testNRforCCwhereStopsLT3Cyclic(self):
    (result, routes) = self.graph.get_routes('CC', 'cyclic', 'stops', 'lt', '3')
    print "result == {0}".format(result)
    print "routes == {0}".format(routes)
    self.failIf(result != 0)
    self.failIf(set(routes) != set(['CEBC', 'CDC']))

  def testNRforACwhereStopsEQ3Cyclic(self):
    (result, routes) = self.graph.get_routes('AC', 'cyclic', 'stops', 'eq', '3')
    print "result == {0}".format(result)
    print "routes == {0}".format(routes)
    self.failIf(result != 0)
    self.failIf(set(routes) != set(['ABCDC', 'ADCDC', 'ADEBC']))

  def testRShortestAC(self):
    (result, distance, route) = self.graph.get_shortest_distance('A', 'C')
    print "result   == {0}".format(result)
    print "distance == {0}".format(distance)
    print "route    == {0}".format(route)
    self.failIf(result    != 0)
    self.failIf(route     != 'ABC')
    self.failIf(distance  != 9)

  def testRShortestBB(self):
    (result, distance, route) = self.graph.get_shortest_distance('B', 'B')
    print "result   == {0}".format(result)
    print "distance == {0}".format(distance)
    print "route    == {0}".format(route)
    self.failIf(result    != 0)
    self.failIf(route     != 'BCEB')
    self.failIf(distance  != 9)

  def testNRforCCwhereDistanceLT30Cyclic(self):
    (result, routes) = self.graph.get_routes('CC', 'cyclic', 'distance', 'lt', '30')
    print "result == {0}".format(result)
    print "routes == {0}".format(routes)
    self.failIf(result != 0)
    self.failIf(set(routes) != set(['CEBC', 'CEBCEBC', 'CEBCEBCEBC', 'CEBCDC', 'CDC', 'CDCEBC', 'CDEBC']))    

def main():
  unittest.main()

if __name__ == '__main__':
  main()
