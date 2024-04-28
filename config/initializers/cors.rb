Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://front:4000', 'https://vimemo.vercel.app'
    resource '*',
    headers: :any,
    methods: [:get, :post, :options, :put, :delete],
    credentials: true  
  end
end
