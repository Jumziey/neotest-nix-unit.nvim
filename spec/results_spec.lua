require('plenary.busted')

local adapter = require("neotest-nix-unit")
local nio = require("nio")

local function create_output_file(content)
	local temp_file = vim.fn.tempname()
	vim.fn.writefile(vim.split(content, "\n"), temp_file)
	return temp_file
end

describe("results", function()
	nio.tests.it("should parse successful test results", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = "/just_a_path/to/a_test.tests.nix"
		-- Mock the tree data for a single test
		local tree = {
			data = function()
				return {
					id = test_file,
					name = "a_test.tests.nix",
					path = test_file,
					type = "file"
				}
			end,
			children = function()
				return {
					{
						data = function()
							return {
								id = test_file .. "::testSimple",
								name = "testSimple",
								path = test_file,
								type = "test"
							}
						end
					}
				}
			end
		}

		local output_file = create_output_file([[✅ testSimple

🎉 1/1 successful]])

		local result = {
			output = output_file
		}
		local results = adapter.results(spec, result, tree)
		local expected_results = {
			[test_file .. "::testSimple"] = {
				status = "passed",
			}
		}
		assert.same(expected_results, results)
	end)
	nio.tests.it("should parse successful test results, despite weird nix error to start with", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = "/just_a_path/to/a_test.tests.nix"
		-- Mock the tree data for a single test
		local tree = {
			data = function()
				return {
					id = test_file,
					name = "a_test.tests.nix",
					path = test_file,
					type = "file"
				}
			end,
			children = function()
				return {
					{
						data = function()
							return {
								id = test_file .. "::testSimple",
								name = "testSimple",
								path = test_file,
								type = "test"
							}
						end
					}
				}
			end
		}

		local output_file = create_output_file([[warning: unknown setting 'allowed-users'
warning: unknown setting 'trusted-users'
warning: `--gc-roots-dir' not specified
✅ testSimple

🎉 1/1 successful]])

		local result = {
			output = output_file
		}
		local results = adapter.results(spec, result, tree)
		local expected_results = {
			[test_file .. "::testSimple"] = {
				status = "passed",
			}
		}
		assert.same(expected_results, results)
	end)

	nio.tests.it("should parse failed test results", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = "/just_a_path/to/a_test.tests.nix"
		-- Mock the tree data for a single test
		local tree = {
			data = function()
				return {
					id = test_file,
					name = "a_test.tests.nix",
					path = test_file,
					type = "file"
				}
			end,
			children = function()
				return {
					{
						data = function()
							return {
								id = test_file .. "::testSimple",
								name = "testSimple",
								path = test_file,
								type = "test"
							}
						end
					}
				}
			end
		}

		local output_file = create_output_file([[❌ testSimple
/tmp/nix-764887-3258144437/expected.nix --- Nix
1 { x = 1; }                1 { y = 1; }



😢 0/1 successful
error: Tests failed
]])

		local result = {
			output = output_file
		}
		local results = adapter.results(spec, result, tree)
		local expected_results = {
			[test_file .. "::testSimple"] = {
				status = "failed",
				short = [[/tmp/nix-764887-3258144437/expected.nix --- Nix
1 { x = 1; }                1 { y = 1; }]]
			}
		}
		assert.same(expected_results, results)
	end)
	nio.tests.it("should parse 1 failed and 1 succeeding test result", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = "/just_a_path/to/a_test.tests.nix"
		-- Mock the tree data for a single test
		local tree = {
			data = function()
				return {
					id = test_file,
					name = "two_test.tests.nix",
					path = test_file,
					type = "file"
				}
			end,
			children = function()
				return {
					{
						data = function()
							return {
								id = test_file .. "::testFail",
								name = "testFail",
								path = test_file,
								type = "test"
							}
						end,
						children = function ()
							return {}
						end
					},
					{
						data = function()
							return {
								id = test_file .. "::testSucceed",
								name = "testSucceed",
								path = test_file,
								type = "test"
							}
						end,
						children = function ()
							return {}
						end
					}
				}
			end
		}

		local output_file = create_output_file([[❌ testFail
/tmp/nix-821501-3185973530/expected.nix --- Nix
1 { x = 1; }                1 { y = 1; }


✅ testSucceed

😢 1/2 successful
error: Tests failed
]])

		local result = {
			output = output_file
		}
		local results = adapter.results(spec, result, tree)
		local expected_results = {
			[test_file .. "::testFail"] = {
				status = "failed",
				short = [[/tmp/nix-821501-3185973530/expected.nix --- Nix
1 { x = 1; }                1 { y = 1; }]]
			},
			[test_file .. "::testSucceed"] = {
				status = "passed",
			}
		}
		assert.same(expected_results, results)
	end)
	nio.tests.it("should handle error in nix code", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = "a/path/to/somewhere/error.tests.nix"
		-- Mock the tree data for a single test
		local tree = {
			data = function()
				return {
					id = test_file,
					name = "error.tests.nix",
					path = test_file,
					type = "file"
				}
			end,
			children = function()
				return {
					{
						data = function()
							return {
								id = test_file .. "::testSingle",
								name = "testSingle",
								path = test_file,
								type = "test"
							}
						end,
						children = function ()
							return {}
						end
					}
				}
			end
		}

		local output_file = create_output_file([[error: undefined variable 'a'
       at /home/jumzi/code/dotfiles/flakes/nixvim/plugins/neotest-nix-unit.nvim/example_tests/error.tests.nix:3:18:
            2|   testSingle = {
            3|     expr = { x = a; };
             |                  ^
            4|     expected = { y = 1; };
]])

		local result = {
			output = output_file
		}
		local results = adapter.results(spec, result, tree)
		local expected_results = {
			[test_file] = {
				status = "failed",
				errors = {
					{
						message = "undefined variable 'a'",
						line = 3
					}
				}
			}
		}
		assert.same(expected_results, results)
	end)

	nio.tests.it("should handle throw in nix code", function()
		local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
		local test_file = "a/path/to/somewhere/error.tests.nix"
		-- Mock the tree data for a single test
		local tree = {
			data = function()
				return {
					id = test_file,
					name = "error.tests.nix",
					path = test_file,
					type = "file"
				}
			end,
			children = function()
				return {
					{
						data = function()
							return {
								id = test_file .. "::testFailEval",
								name = "testFailEval",
								path = test_file,
								type = "test"
							}
						end,
						children = function ()
							return {}
						end
					}
				}
			end
		}

		local output_file = create_output_file([[☢️ testFailEval
error:
       … while calling the 'throw' builtin
         at /home/jumzi/code/dotfiles/flakes/nixvim/plugins/neotest-nix-unit.nvim/example_tests/throw_error.tests.nix:3:12:
            2|   testFailEval = {
            3|     expr = throw "NO U";
             |            ^
            4|     expected = 0;

       error: NO U


😢 0/1 successful
error: Tests failed
]])

		local result = {
			output = output_file
		}
		local results = adapter.results(spec, result, tree)
		local expected_results = {
			[test_file .. "::testFailEval"] = {
				status = "failed",
				errors = {
					{
						message = "… while calling the 'throw' builtin",
						line = 3
					}
				}
			}
		}
		assert.same(expected_results, results)
	end)
	-- test throw
end)
