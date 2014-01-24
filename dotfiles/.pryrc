#!/usr/bin/env ruby

require 'win32console' if RUBY_PLATFORM =~ /(mswin|mingw|cygwin)32$/i

begin
  require 'hirb'
rescue LoadError
  # no pretty console output :(
end

if defined? Hirb
  # Slightly dirty hack to fully support in-session Hirb.disable/enable toggling
  Hirb::View.instance_eval do
    def enable_output_method
      @output_method = true
      @old_print = Pry.config.print
      Pry.config.print = proc do |output, value|
        Hirb::View.view_or_page_output(value) || @old_print.call(output, value)
      end
    end

    def disable_output_method
      Pry.config.print = @old_print
      @output_method = nil
    end
  end

  Hirb.enable
end


# Load plugins (only those I whitelist)
#Pry.config.should_load_plugins = false
#Pry.plugins["doc"].activate!
#Pry.plugins["theme"].activate!

# Use vim as my editor
Pry.config.editor = 'vim'
# Set the pry-theme
Pry.config.theme = 'monokai'

# My pry is polite
Pry.config.hooks.add_hook(:after_session, :say_bye) do
  puts "bye-bye"
end

# Prompt with ruby version
Pry.prompt = [
  proc { |object, nest_level|

    object_info = if object == Object || object.class == Object then
      "#{object.class}##{object.inspect}"
    else

      if object.is_a? Class then
        "#{object.class}##{object.superclass}/#{object.name}"
      elsif object.is_a? Module then
        "#{object.class}##{object.name}"
      elsif defined?(RSpec) && defined?(RSpec::Core) && object.is_a?(RSpec::Core::ExampleGroup) then
        "RSpec::Core::ExampleGroup#instance"
      else
        "#{object.class.superclass}/#{object.class}#instance"
      end
    end

    "#{RUBY_VERSION} (#{object_info}):#{nest_level} > "
  },
  proc { |object, nest_level|
    "#{RUBY_VERSION} #{nest_level} * "
  }
]

# Toy methods
# Stealed from https://gist.github.com/807492
class Array
  def self.toy(n=10, &block)
    block_given? ? Array.new(n,&block) : Array.new(n) {|i| i+1}
  end
end

class Hash
  def self.toy(n=10)
    Hash[Array.toy(n).zip(Array.toy(n){|c| (96+(c+1)).chr})]
  end
end

unless defined? Rails
  # Launch Pry with access to the entire Rails stack. (WiP)
  $rails = File.join Dir.getwd, 'config', 'environment.rb'

  if File.exist?($rails) && ENV['SKIP_RAILS'].nil?
    puts 'Rails environment available. Type `rails` to get access to the full stack.'

    def _find_gemfile path = nil
      default_gemfile_path = (ENV['BUNDLE_GEMFILE'] || '').gsub(/Gemfile/,'')
      path ||= File.expand_path(default_gemfile_path || Dir.pwd)

      filename = File.join(path, 'Gemfile')
      if File.file?(filename)
        filename
      else
        next_path = File.expand_path('..', path)
        unless path == next_path then
          _find_gemfile next_path
        else
          warn 'Gemfile not found!'
          false
        end
      end
    end

    def _bundler_require origin_path = nil
      gemfile_path = _find_gemfile
      if gemfile_path then
        ENV['BUNDLE_GEMFILE'] = gemfile_path
        Bundler.require(:default, (ENV['RAILS_ENV'] || :development))
      end
    end

    def rails
      puts "[INFO] loading Rails..."

      require 'bundler'

      begin
        require 'active_record'
      rescue LoadError
      end

      if _bundler_require then

        require $rails

        require 'rails/console/app'
        require 'rails/console/helpers'

        if defined? ActiveRecord then
          ActiveRecord::Base.logger = Logger.new(STDOUT)
        end

        Rails
      end
    end
  end
end
