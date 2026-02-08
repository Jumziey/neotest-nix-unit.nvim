# NOT CURRENTLY SUPPORTED IN NEOTEST-NIX-UNIT.nvim
let tests = import ./nested.tests.nix; in
{
  testOne = tests.nested.testOne;
  testTwo = tests.nested.testTwo;
}
