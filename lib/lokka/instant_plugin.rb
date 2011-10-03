module Lokka
  module InstantPlugin
    def self.registered(app)
      app.set :instant_plugins, []
      #app.set :git_themes, {}
      app.get '/admin/plugins/instant_plugin' do
        #puts app.instance_variable_get(:@routes)['GET'].map(&:first)
        haml :"plugin/lokka-instant_plugin/views/index", :layout => :"admin/layout"
      end
      app.post '/admin/plugins/instant_plugin' do
        plugin_path = params['plugin_path']

        if plugin_path =~ /^git:/
          FileUtils.makedirs 'tmp/cache'
          FileUtils.chdir 'tmp/cache' do
            exec_git(plugin_path)
          end
          flash[:notice] = 'Fetched.'
        else

          #begin
            io = ::IO.respond_to?(:binread) ? ::IO.binread(plugin_path) : ::IO.read(plugin_path)
            code, view = io.gsub("\r\n", "\n").split(/^__END__$/, 2)
          #rescue Errno::ENOENT
          #  code, view = nil
          #end

          paths = plugin_path.split(File::SEPARATOR)
          name, ext = paths.last.split('.')

          if code
            eval(code, TOPLEVEL_BINDING)
            #begin
            plugin = ::Lokka.const_get(name.camelize)
            app.register plugin
            if view
              lines = code.count("\n") + 1
              template = nil
              view.each_line do |line|
                lines += 1
                if line =~ /^@@\s*(.*\S)\s*$/
                  template = ''
                  # template name starts with "inline:"
                  app.templates["inline:#{name}/#{$1}".to_sym] = [template, plugin_path, lines]
                elsif template
                  template << line
                end
              end
            end


            #rescue => e
            #  puts "plugin #{plugin_path} is identified as a suspect."
            #  puts e
            #end
            settings.instant_plugins << [name, plugin_path]
            flash[:notice] = 'Updated.'
          else
            flash[:notice] = 'Error.'
          end
        end
        redirect '/admin/plugins/instant_plugin'
      end

      app.post '/admin/plugins/instant_plugin/themes' do
        theme_url = params['theme_url']
        if theme_url =~ /^git:/
          user, theme_git = theme_url.split('/').last(2)
          theme_name = theme_git.split('.').first
          #reg_exts = {}
          FileUtils.makedirs 'tmp/cache'
          FileUtils.chdir 'tmp/cache' do
            exec_git(theme_url)
            exts = settings.supported_templates.join(',')
            Dir.glob("#{theme_name}/*.{#{exts}}") do |path|
              name, ext = path.split('.')
              view = ::IO.respond_to?(:binread) ? ::IO.binread(path) : ::IO.read(path)
              lines = view.count("\n") + 1
              settings.templates["git:#{name}".to_sym] = [view, "git:#{path}", lines]
              #reg_exts[name] = ext
            end
          end
          site = Site.first
          site.update(:theme => theme_name)
          #settings.git_themes[theme_name] = reg_exts
          app.set :gh_pages_path, "http://#{user}.github.com/#{theme_name}"
        end
        flash[:notice] = 'Fetched theme & Applied.'
        redirect '/admin/plugins/instant_plugin'
      end
      #app.before do
      #end
      #app.post '/admin/plugins/instant_plugin/add_route' do
      #  app.get "/#{params['path']}" do
      #    "Hello #{params['path']}"
      #  end
      #  flash[:notice] = "Added #{params['path']}."
      #  redirect '/admin/plugins/instant_plugin'
      #end
    end
  end

  module Helpers
    def exec_git(path)
      command = %|clone "#{path}"|
      out = %x{git #{command}}

      if $?.exitstatus != 0
        msg = "Git error: command `git #{command}` in directory #{Dir.pwd} has failed."
        msg << "\nIf this error persists you could try removing the cache directory '#{cache_path}'" if cached?
        raise Bundler::GitError, msg
      end
      puts out # better way to debug?
      out
    end

    # override
    def rendering(ext, name, options = {})
      locals = options[:locals] ? {:locals => options[:locals]} : {}
      dir =
        if request.path_info =~ %r{^/admin/.*}
          'admin'
        else
          "theme/#{@theme.name}"
        end

      layout = "#{dir}/layout"
      path =
        if settings.supported_stylesheet_templates.include?(ext)
          "#{name}"
        else
          "#{dir}/#{name}"
        end

      if File.exist?("#{settings.views}/#{layout}.#{ext}")
        options[:layout] = layout.to_sym if options[:layout].nil?
      elsif t = settings.templates["git:#{@theme.name}/layout".to_sym] and
            t[1].end_with?(".#{ext}")
        options[:layout] = "git:#{@theme.name}/layout".to_sym if options[:layout].nil?
      end
      if File.exist?("#{settings.views}/#{path}.#{ext}")
        send(ext.to_sym, path.to_sym, options, locals)
      elsif t = settings.templates["git:#{@theme.name}/#{name}".to_sym] and
            t[1].end_with?(".#{ext}")
        @theme.instance_variable_set :@path, settings.gh_pages_path
        send(ext.to_sym, "git:#{@theme.name}/#{name}".to_sym, options, locals)
      end
    end
  end
end