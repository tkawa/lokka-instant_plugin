# Example: input path "public/plugin/lokka-instant_plugin/sample/hello2.rb"
module Lokka
  module Hello2
    def self.registered(app)
      app.get '/instant/hello2' do
        haml :"inline/index"
      end
      app.get '/instant/hello2/string' do
        haml "%div string template is OK"
      end
      app.get '/instant/hello2/:name' do
        @name = params[:name]
        haml :"inline/show"
      end
    end
  end

  module Helpers
    def hello2
      'hello2'
    end
  end
end

__END__

@@ index
%div inline template is in progress..

@@ show
%div
  %span show
  %span= @name