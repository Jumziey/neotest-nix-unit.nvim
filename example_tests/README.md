# Example tests
Test here just meanth to be run with nix-unit for experimentation.

# Commands for running tests
  
## Simple command
nix-unit <file>

## With lib (need to be assumed, or configured)
nix-unit <file> --arg lib '(import <nixpkgs> {}).lib'

## Single test
### In example_tests
nix-unit --expr '{ testPass = (import ./simple.tests.nix).testFail; }'
### Generally
nix-unit --expr '{ <test_name> = (import <test-file-path> ).<test_name>; }'


## Nested tests (namespaced)
### In example_tests
nix-unit --expr '(import ./nested.tests.nix).nested'
### Generally
nix-unit --expr '(import <test-file-path>).<namespace>'

## Single test from a nest (namespace)
### In example_tests
nix-unit --expr '{ testOne = (import ./nested.tests.nix).nested.testOne; }'
### Generally
nix-unit --expr '{ <test_name> = (import <test-file-path>).<namespace>.<test_name>; }'

## Run nested tests in a nested structure (namespace within namespace)
### In example_tests
nix-unit --expr '(import ./nested.tests.nix).nested.yetAnotherNest'
### Generally
nix-unit --expr '(import <test-file-path>).<namespace>' 
### Note
namespace is nested.yetAnotherNest

## Run single test from nested tests in a nested structure 
### In example_tests
nix-unit --expr '{ testInceptionRed = (import ./nested.tests.nix).nested.yetAnotherNest.testInceptionRed; }'
### Generally
nix-unit --expr '{ <test_name> = (import <test-file-path>).<namespace>.<test_name>; }'
### Note
namespace is nested.yetAnotherNest
