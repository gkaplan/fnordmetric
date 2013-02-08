# encoding: utf-8

class FnordMetric::App < Sinatra::Base

  include FnordMetric::AppHelpers

  if RUBY_VERSION =~ /1.9.\d/
    Encoding.default_external = Encoding::UTF_8
  end

  if ENV['RACK_ENV'] == "test"
    set :raise_errors, true
  end

  enable :session
  set :haml, :format => :html5
  set :views, ::File.expand_path('../../../../web/haml', __FILE__)
  set :public_folder, ::File.expand_path('../../../../web', __FILE__)

  helpers do
    include Rack::Utils    
    include FnordMetric::AppHelpers
  end

  def initialize(opts = {})
    @opts = FnordMetric.default_options(opts)

    @namespaces = FnordMetric.namespaces
    @redis = Redis.connect(:url => @opts[:redis_url])

    super(nil)
  end

  get '/' do
    redirect "#{path_prefix}/#{@namespaces.keys.first}"
  end

  get '/:namespace' do
    pass unless current_namespace
    haml :app
  end

  post '/events' do
    halt 400, 'please specify the event_type (_type)' unless params["_type"]
    track_event((8**32).to_s(36), parse_params(params))
  end

  get '/fnordmetric-ui.js' do
    files = [
      '/js/d3.fnordmetric.js',
      '/js/rickshaw.fnordmetric.js',
      '/js/fnordmetric.js',
      '/js/fnordmetric.util.js',
      '/js/fnordmetric.timeseries_widget.js',
      '/js/fnordmetric.js_api.js'
    ]

    unless ENV["FNORDMETRIC_ENV"] == "dev"
      merged_js = @merged_js_cached
    end

    unless merged_js
      merged_js = ""

      files.each do |file|
        file = ::File.expand_path("../../../../web#{file}", __FILE__)
        merged_js += IO.read(file)
      end

      @merged_js_cached = merged_js
    end

    content_type "application/javascript"
    merged_js
  end

  # FIXPAUL move to websockets
  get '/:namespace/dashboard/:dashboard' do
    dashboard = current_namespace.dashboards.fetch(params[:dashboard])

    dashboard.to_json
  end

end

