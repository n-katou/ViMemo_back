Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://front:4000'  # Next.jsがローカルで実行されている場合
    resource '*',
    headers: :any,
    methods: [:get, :post, :options, :put, :delete],
    credentials: true  
  end
end
