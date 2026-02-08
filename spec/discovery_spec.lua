require('plenary.busted') -- for lsp to load signatures

local adapter = require("neotest-nix-unit")
local nio = require("nio")

describe("discover_positions", function()
	nio.tests.it("should discover single tests in a file with one test", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = test_dir .. "/discovery_test/single.tests.nix"

		local file = adapter.discover_positions(test_file)
		local simple_test = file:children()[1]

		local expectedFilePosition = {
			id = test_file,
			name = "single.tests.nix",
			path = test_file,
			range = { 0, 0, 6, 0 },
			type = "file"
		}

		local expectedSingleTestPosition = {
			id = test_file .. "::testSingle",
			name = "testSingle",
			path = test_file,
			range = { 1, 2, 4, 4 },
			type = "test"
		}
		assert.same(expectedFilePosition, file:data())
		assert.same(expectedSingleTestPosition, simple_test:data())
	end)

	nio.tests.it("should discover three tests in a file with three test", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = test_dir .. "/discovery_test/three.tests.nix"

		local file = adapter.discover_positions(test_file)
		local first_test = file:children()[1]
		local second_test = file:children()[2]
		local third_test = file:children()[3]

		local expectedFilePosition = {
			id = test_file,
			name = "three.tests.nix",
			path = test_file,
			range = { 0, 0, 15, 0 },
			type = "file"
		}

		local expectedFirstTestPosition = {
			id = test_file .. "::testFirst",
			name = "testFirst",
			path = test_file,
			range = { 1, 2, 4, 4 },
			type = "test"
		}

		local expectedSecondTestPosition = {
			id = test_file .. "::testSecond",
			name = "testSecond",
			path = test_file,
			range = { 5, 2, 8, 4 },
			type = "test"
		}

		local expectedThirdTestPosition = {
			id = test_file .. "::testThird",
			name = "testThird",
			path = test_file,
			range = { 9, 2, 12, 4 },
			type = "test"
		}

		assert.same(expectedFilePosition, file:data())
		assert.same(expectedFirstTestPosition, first_test:data())
		assert.same(expectedSecondTestPosition, second_test:data())
		assert.same(expectedThirdTestPosition, third_test:data())
	end)

	nio.tests.it("should discover a namespace", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = test_dir .. "/discovery_test/nested.tests.nix"

		local file = adapter.discover_positions(test_file)
		local namespace = file:children()[1]
		local firstNestedTest = namespace:children()[1]
		local secondNestedTest = namespace:children()[2]

 		local expectedNamespace = {
 			id = test_file .. "::nested",
 			name = "nested",
 			path = test_file,
 			range = { 1, 2, 10, 4 },
 			type = "namespace"
 		}
 		local expectedFirstNestedTest = {
 			id = test_file .. "::nested::testFirstNested",
 			name = "nested.testFirstNested",
 			path = test_file,
 			range = { 2, 4, 5, 6 },
 			type = "test"
 		}
 		local expectedSecondNestedTest = {
 			id = test_file .. "::nested::testSecondNested",
 			name = "nested.testSecondNested",
 			path = test_file,
 			range = { 6, 4, 9, 6 },
 			type = "test"
 		}

		assert.same(expectedNamespace, namespace:data())
		assert.same(expectedFirstNestedTest, firstNestedTest:data())
		assert.same(expectedSecondNestedTest, secondNestedTest:data())
	end)

	nio.tests.it("should discover doubly nested namespace", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = test_dir .. "/discovery_test/double_nested.tests.nix"

		local file = adapter.discover_positions(test_file)
		local namespace = file:children()[1]
		local nestedNamespace = namespace:children()[1]
		local doublyNestedTest = nestedNamespace:children()[1]


 		local expectedNamespace = {
 			id = test_file .. "::nested",
 			name = "nested",
 			path = test_file,
 			range = { 1, 2, 8, 4 },
 			type = "namespace"
 		}
 		local expectedNestedNamespace = {
 			id = test_file .. "::nested::secondNested",
 			name = "nested.secondNested",
 			path = test_file,
 			range = { 2, 4, 7, 6 },
 			type = "namespace"
 		}
 		local expectedDoublyNestedTest = {
 			id = test_file .. "::nested::secondNested::testDoublyNested",
 			name = "nested.secondNested.testDoublyNested",
 			path = test_file,
 			range = { 3, 6, 6, 8 },
 			type = "test"
 		}

		assert.same(expectedNamespace, namespace:data())
		assert.same(expectedNestedNamespace, nestedNamespace:data())
		assert.same(expectedDoublyNestedTest, doublyNestedTest:data())
	end)

	nio.tests.it("should discover test without namespaces when namespaces exists", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = test_dir .. "/discovery_test/nested_and_no_nest.tests.nix"

		local file = adapter.discover_positions(test_file)
		local noNestTest = file:children()[1]
		local namespace = file:children()[2]
		local firstNestedTest = namespace:children()[1]
		local secondNestedTest = namespace:children()[2]

 		local expectedTestWithoutNest = {
 			id = test_file .. "::testWithoutNest",
 			name = "testWithoutNest",
 			path = test_file,
 			range = { 1, 2, 4, 4 },
 			type = "test"
 		}

 		local expectedNamespace = {
 			id = test_file .. "::nested",
 			name = "nested",
 			path = test_file,
 			range = { 6, 2, 15, 4 },
 			type = "namespace"
 		}
 		local expectedFirstNestedTest = {
 			id = test_file .. "::nested::testFirstNested",
 			name = "nested.testFirstNested",
 			path = test_file,
 			range = { 7, 4, 10, 6 },
 			type = "test"
 		}
 		local expectedSecondNestedTest = {
 			id = test_file .. "::nested::testSecondNested",
 			name = "nested.testSecondNested",
 			path = test_file,
 			range = { 11, 4, 14, 6 },
 			type = "test"
 		}

		assert.same(expectedTestWithoutNest, noNestTest:data())
		assert.same(expectedNamespace, namespace:data())
		assert.same(expectedFirstNestedTest, firstNestedTest:data())
		assert.same(expectedSecondNestedTest, secondNestedTest:data())
	end)

	nio.tests.it("should discover tests in a file with let/in", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = test_dir .. "/discovery_test/let-in.tests.nix"

		local file = adapter.discover_positions(test_file)
		local simple_test = file:children()[1]

		local expectedFilePosition = {
			id = test_file,
			name = "let-in.tests.nix",
			path = test_file,
			range = { 0, 0, 13, 0 },
			type = "file"
		}

		local expectedSingleTestPosition = {
			id = test_file .. "::testUsingVar",
			name = "testUsingVar",
			path = test_file,
			range = { 4, 2, 11, 4 },
			type = "test"
		}
		assert.same(expectedFilePosition, file:data())
		assert.same(expectedSingleTestPosition, simple_test:data())
	end)

	nio.tests.it("should discover a simple test with a nested attrset", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = test_dir .. "/discovery_test/nested_attrset.tests.nix"

		local file = adapter.discover_positions(test_file)
		local first_test = file:children()[1]
		local second_test = file:children()[2]

		local expectedFilePosition = {
			id = test_file,
			name = "nested_attrset.tests.nix",
			path = test_file,
			range = { 0, 0, 10, 0 },
			type = "file"
		}

		local expectedFirstTestPosition = {
			id = test_file .. "::testFail",
			name = "testFail",
			path = test_file,
			range = { 1, 2, 4, 4 },
			type = "test"
		}

		local expectedSecondTestPosition = {
			id = test_file .. "::testSucceed",
			name = "testSucceed",
			path = test_file,
			range = { 5, 2, 8, 4 },
			type = "test"
		}
		assert.same(expectedFilePosition, file:data())
		assert.same(expectedFirstTestPosition, first_test:data())
		assert.same(expectedSecondTestPosition, second_test:data())
	end)


end)
