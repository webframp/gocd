module Bundler
  class CLI::Config
    attr_reader :options, :thor
    attr_accessor :args

    def initialize(options, args, thor)
      @options = options
      @args = args
      @thor = thor
    end

    def run
      peek = args.shift

      if peek && peek =~ /^\-\-/
        name, scope = args.shift, $'
      else
        name, scope = peek, "global"
      end

      unless name
        Bundler.ui.confirm "Settings are listed in order of priority. The top value will be used.\n"

        Bundler.settings.all.each do |setting|
          Bundler.ui.confirm "#{setting}"
          thor.with_padding do
            Bundler.settings.pretty_values_for(setting).each do |line|
              Bundler.ui.info line
            end
          end
          Bundler.ui.confirm ""
        end
        return
      end

      case scope
      when "delete"
        Bundler.settings.set_local(name, nil)
        Bundler.settings.set_global(name, nil)
      when "local", "global"
        if args.empty?
          Bundler.ui.confirm "Settings for `#{name}` in order of priority. The top value will be used"
          thor.with_padding do
            Bundler.settings.pretty_values_for(name).each { |line| Bundler.ui.info line }
          end
          return
        end

        locations = Bundler.settings.locations(name)

        if scope == "global"
          if local = locations[:local]
            Bundler.ui.info "Your application has set #{name} to #{local.inspect}. This will override the " \
              "global value you are currently setting"
          end

          if env = locations[:env]
            Bundler.ui.info "You have a bundler environment variable for #{name} set to #{env.inspect}. " \
              "This will take precedence over the global value you are setting"
          end

          if global = locations[:global]
            Bundler.ui.info "You are replacing the current global value of #{name}, which is currently #{global.inspect}"
          end
        end

        if scope == "local" && local = locations[:local]
          Bundler.ui.info "You are replacing the current local value of #{name}, which is currently #{local.inspect}"
        end

        if name.match(/\Alocal\./)
          pathname = Pathname.new(args.join(" "))
          self.args = [pathname.expand_path.to_s] if pathname.directory?
        end

        Bundler.settings.send("set_#{scope}", name, args.join(" "))
      else
        Bundler.ui.error "Invalid scope --#{scope} given. Please use --local or --global."
        exit 1
      end
    end

  end
end
