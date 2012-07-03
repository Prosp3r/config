require 'win32console' if RUBY_PLATFORM =~ /(mswin|mingw|cygwin)32$/i

begin
  require 'hirb'
rescue LoadError
  # no pretty console output :(
end

Hirb.enable if defined? Hirb

# Load plugins (only those I whitelist)
#Pry.config.should_load_plugins = false
Pry.config.editor = 'vim'
#Pry.plugins["doc"].activate!

# Some special sauce for Rails

# Launch Pry with access to the entire Rails stack.
rails = File.join Dir.getwd, 'config', 'environment.rb'

if File.exist?(rails) && ENV['SKIP_RAILS'].nil?
  puts 'Rails environment available. Type load_rails to get access to the full stack.'

  def load_rails
    puts "[INFO] loading Rails..."
    require rails

    if Rails.version[0..0] == "2"
      require 'console_app'
      require 'console_with_helpers'
    elsif Rails.version[0..0] == "3"
      require 'rails/console/app'
      require 'rails/console/helpers'

      ActiveRecord::Base.logger = Logger.new(STDOUT)
    else
      warn "[WARN] cannot load Rails console commands (Not on Rails2 or Rails3?)"
    end
  end
end