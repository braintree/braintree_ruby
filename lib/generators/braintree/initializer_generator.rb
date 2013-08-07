module Braintree
  module Generators
    class InitializerGenerator < ::Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      desc 'Create a Braintree initializer in config/initializers.'
      def copy_initializer
        copy_file 'braintree.rb', 'config/initializers/braintree.rb'
      end

    end
  end
end
