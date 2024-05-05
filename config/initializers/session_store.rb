# Rails.application.config.session_store :redis_store, servers: [
#   {
#     host: ENV['REDIS_HOST'],
#     port: ENV['REDIS_PORT'],
#     db: 0,
#     password: ENV['REDIS_PASSWORD'],
#     namespace: "session"
#   }
# ], expire_after: 90.minutes, key: "_#{Rails.application.class.module_parent_name.downcase}_session",threadsafe: true,
# secure: Rails.env.production?,same_site: Rails.env.production? ? :none : :lax
