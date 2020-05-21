$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest"
require "minitest/fork_executor"
Minitest.parallel_executor = Minitest::ForkExecutor.new

require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require "minitest/autorun"
