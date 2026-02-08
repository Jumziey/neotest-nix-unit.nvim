{
  testSimple = {
    expr = 1;
    expected = 1;
  };

  nested = {
    yetAnotherNest = {
      testInception = {
        expr = "blue";
        expected = "blue";
      };
      testInceptionRed = {
        expr = "red";
        expected = "red";
      };
    };
    testOne = {
      expr = "foo";
      expected = "foo";
    };
    testTwo = {
      expr = "bar";
      expected = "bar";
    };
    testFail = {
      expr = "foo";
      expected = "bar";
    };
  };
}
