module Lokka
  module InstantPlugin
    def self.registered(app)
      #puts (app.methods - Object.methods)
      app.set :instant_plugins, []
      app.get '/admin/plugins/instant_plugin' do
        #puts app.instance_variable_get(:@routes)['GET'].map(&:first)
        haml :"plugin/lokka-instant_plugin/views/index", :layout => :"admin/layout"
      end
      app.post '/admin/plugins/instant_plugin' do
        file = params['plugin_path']

        #begin
          io = ::IO.respond_to?(:binread) ? ::IO.binread(file) : ::IO.read(file)
          code, view = io.gsub("\r\n", "\n").split(/^__END__$/, 2)
        #rescue Errno::ENOENT
        #  code, view = nil
        #end

        paths = file.split(File::SEPARATOR)
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
                # template name cannot set yet
                app.templates["inline/#{$1}".to_sym] = [template, file, lines]
              elsif template
                template << line
              end
            end
          end


          #rescue => e
          #  puts "plugin #{file} is identified as a suspect."
          #  puts e
          #end
          settings.instant_plugins << [name, file]
          flash[:notice] = 'Updated.'
        else
          flash[:notice] = 'Error.'
        end
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
end