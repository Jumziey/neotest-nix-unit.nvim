let
  testVar = "just a";

in {
  testUsingVar = {
    expr = {
      expression = testVar;
    };
    expected = {
      expression = "just a" ;
    };
  };
}
