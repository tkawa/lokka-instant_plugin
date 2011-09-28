module Lokka
  module Redirector
    def self.registered(app)
      app.set :redirector, []
      app.get '/admin/plugins/redirector' do
        haml :"inline:redirector/index", :layout => :"admin/layout"
      end
      app.post '/admin/plugins/redirector' do
        # TODO: register redirect path
        path_from, path_to = params['from'], params['to']
        app.get path_from do
          redirect path_to
        end
        route = settings.routes['GET'].pop
        settings.routes['GET'].unshift(route)
        settings.redirector << [path_from, path_to, params['status']]
        flash[:notice] = 'Updated.'
        redirect '/admin/plugins/redirector'
      end
      app.delete '/admin/plugins/redirector/:id' do |id|
        # TODO: remove redirect path
        #settings.routes['GET'].delete
        id = id.to_i
        settings.redirector[id] = nil
        flash[:notice] = 'Removed.'
        redirect '/admin/plugins/redirector'
      end
    end
  end
end

__END__

@@ index
%h2 Redirector Plugin (Instant Plugin)
%ul.plugins
  - settings.redirector.each_with_index do |(from, to, status), id|
    - if from
      %li
        = from
        %br
        = to
        (#{status})
        %form{:action => "/admin/plugins/redirector/#{id}", :method => 'post'}
          %input{:type => 'hidden', :name => '_method', :value => 'delete'}
          %input{:type => 'submit', :value => 'remove'}
%form{:action => '/admin/plugins/redirector', :method => 'post'}
  .field
    %label{:for => 'from'} Path from (e.g. /hoge)
    %input{:type => 'text', :id => 'from', :name => 'from'}
    %br
    %label{:for => 'to'} Path to (e.g. /hoge2)
    %input{:type => 'text', :id => 'to', :name => 'to'}
    %br
    %label{:for => 'status'} Redirect status code (must 3xx)
    %input{:type => 'text', :id => 'status', :name => 'status', :value => '302'}
  .field
    %input{:type => 'submit', :value => 'register'}
