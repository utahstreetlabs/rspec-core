module RSpec
  module Core
    class CommandLine
      def initialize(options, configuration=RSpec::configuration, world=RSpec::world)
        if Array === options
          options = ConfigurationOptions.new(options)
          options.parse_options
        end
        @options       = options
        @configuration = configuration
        @world         = world
      end

      # Configures and runs a suite
      #
      # @param [IO] err
      # @param [IO] out
      def run(err, out)
        @configuration.error_stream = err
        @configuration.output_stream ||= out
        @options.configure(@configuration)
        @configuration.load_spec_files
        @world.announce_filters

        @configuration.reporter.report(@world.example_count, @configuration.randomize? ? @configuration.seed : nil) do |reporter|
          begin
            @configuration.run_hook(:before, :suite)
            (1..@configuration.example_group_retries).inject(@world.example_groups.ordered) do |groups, i|
              out.puts "attempt #{i}"
              groups.reject {|g| g.run(reporter)}
            end.any? ? @configuration.failure_exit_code : 0
          ensure
            @configuration.run_hook(:after, :suite)
          end
        end
      end
    end
  end
end
