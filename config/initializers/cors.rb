Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://front:4000', 'http://localhost:4000', 'https://vimemo.vercel.app', 'https://vimemo.fly.dev'
    resource '*',
    headers: :any,
    methods: [:get, :post, :patch, :put, :delete, :options, :head],
    credentials: true  
  end
end
