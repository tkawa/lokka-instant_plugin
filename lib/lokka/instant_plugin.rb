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
          code, data = io.gsub("\r\n", "\n").split(/^__END__$/, 2)
        #rescue Errno::ENOENT
        #  app, data = nil
        #end

        paths = file.split(File::SEPARATOR)
        name, ext = paths.last.split('.')

        if code
          eval(code, TOPLEVEL_BINDING)
          #begin
            plugin = ::Lokka.const_get(name.camelize)
            app.register plugin
          #rescue => e
          #  puts "plugin #{file} is identified as a suspect."
          #  puts e
          #end
          settings.instant_plugins << name
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