require 'virtus/xsd/generation/ruby_code_builder'
require 'active_support/core_ext/string/inflections'

module Virtus
  module Xsd
    class RubyGenerator
      def initialize(type_definitions, opts = {})
        @type_definitions = type_definitions
        @options = opts
      end

      def generate_classes
        @type_definitions.each { |type_definition| generate_class(type_definition) }
      end

      private

      def generate_class(type_definition)
        return if type_definition.base?
        output_for(type_definition) do |output|
          builder = Generation::RubyCodeBuilder.new(output)
          builder.class_(type_definition.name,
                         superclass: type_definition.superclass && type_definition.superclass.name,
                         module_name: module_name) do
            builder.invoke_pretty 'include', 'Virtus.model'
            builder.blank_line
            type_definition.attributes.values.each do |attr|
              builder.invoke_pretty 'attribute', ":#{attr.name}", attr.type.name
            end
          end
        end
      end

      def output_for(type_definition)
        file_path = generate_file_name(type_definition)
        FileUtils.mkdir_p(File.dirname(file_path))
        output = File.new(file_path, 'w')
        yield output
      ensure
        output.close if output
      end

      def generate_file_name(type_definition)
        module_path = (module_name || '').underscore.split('/')
        File.join(output_dir, *module_path, "#{type_definition.name.underscore}.rb")
      end

      def output_dir
        @options[:output_dir]
      end

      def module_name
        @options[:module_name]
      end

      private

      def within_module(module_name)
        parts = module_name.split('::', 2)
        puts "module #{parts.first}"
        if parts.length > 1
          module_(parts.second) { yield }
        else
          ident { yield }
        end
        puts "end"
      end
    end
  end
end