require('plenary.busted')

local adapter = require("neotest-nix-unit")
local nio = require("nio")

local function create_output_file(content)
	local temp_file = vim.fn.tempname()
	vim.fn.writefile(vim.split(content, "\n"), temp_file)
	return temp_file
end

describe("results with nested tests", function()
	nio.tests.it("should parse results for nested tests with dotted notation from nix-unit", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = "/just_a_path/to/nested.tests.nix"
		
		-- Mock the tree data for nested tests
		-- File has namespace "nested" containing tests "testOne" and "testFail"
		-- Names now include namespace path: "nested.testOne", "nested.testFail"
		local tree = {
			data = function()
				return {
					id = test_file,
					name = "nested.tests.nix",
					path = test_file,
					type = "file"
				}
			end,
			children = function()
				return {
					{
						data = function()
							return {
								id = test_file .. "::nested",
								name = "nested",
								path = test_file,
								type = "namespace"
							}
						end,
						children = function()
 							return {
 								{
 									data = function()
 										return {
 											id = test_file .. "::nested::testOne",
 											name = "nested.testOne",
 											path = test_file,
 											type = "test"
 										}
 									end,
 									children = function()
 										return nil
 									end
 								},
 								{
 									data = function()
 										return {
 											id = test_file .. "::nested::testFail",
 											name = "nested.testFail",
 											path = test_file,
 											type = "test"
 										}
 									end,
 									children = function()
 										return nil
 									end
 								}
 							}
						end
					}
				}
			end
		}

		-- nix-unit output uses dotted notation for nested tests
		local output_file = create_output_file([[✅ nested.testOne

❌ nested.testFail
/tmp/nix-138209-79997971/expected.nix --- Nix
1 "foo"                     1 "bar"


😢 1/2 successful
error: Tests failed
]])

		local result = {
			output = output_file
		}
		
		-- Now works because test names match nix-unit output exactly
		local results = adapter.results(spec, result, tree)
		
		local expected_results = {
			[test_file .. "::nested::testOne"] = {
				status = "passed",
			},
			[test_file .. "::nested::testFail"] = {
				status = "failed",
				short = "/tmp/nix-138209-79997971/expected.nix --- Nix\n1 \"foo\"                     1 \"bar\""
			}
		}
		assert.same(expected_results, results)
	end)

	nio.tests.it("should parse results for doubly nested tests with dotted notation", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = "/just_a_path/to/nested.tests.nix"
		
		-- Mock the tree data for doubly nested tests
		-- Names include full path: "nested.yetAnotherNest.testInception"
		local tree = {
			data = function()
				return {
					id = test_file,
					name = "nested.tests.nix",
					path = test_file,
					type = "file"
				}
			end,
			children = function()
				return {
					{
						data = function()
							return {
								id = test_file .. "::nested",
								name = "nested",
								path = test_file,
								type = "namespace"
							}
						end,
						children = function()
							return {
								{
									data = function()
										return {
											id = test_file .. "::nested::yetAnotherNest",
											name = "nested.yetAnotherNest",
											path = test_file,
											type = "namespace"
										}
									end,
 									children = function()
 										return {
 											{
 												data = function()
 													return {
 														id = test_file .. "::nested::yetAnotherNest::testInception",
 														name = "nested.yetAnotherNest.testInception",
 														path = test_file,
 														type = "test"
 													}
 												end,
 												children = function()
 													return nil
 												end
 											}
 										}
									end
								}
							}
						end
					}
				}
			end
		}

		-- nix-unit output uses triple dotted notation for doubly nested tests
		local output_file = create_output_file([[✅ nested.yetAnotherNest.testInception

🎉 1/1 successful
]])

		local result = {
			output = output_file
		}
		
		local results = adapter.results(spec, result, tree)
		
		local expected_results = {
			[test_file .. "::nested::yetAnotherNest::testInception"] = {
				status = "passed",
			}
		}
		assert.same(expected_results, results)
	end)
end)
