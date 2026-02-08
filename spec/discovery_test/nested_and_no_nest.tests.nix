{
  testWithoutNest = {
    expr = "exprValue";
    expected = "expectedValue";
  };

  nested = {
    testFirstNested = {
      expr = "firstExpr";
      expected = "firstValue";
    };
    testSecondNested = {
      expr = "secondExpr";
      expected = "secondValue";
    };
  };
}
