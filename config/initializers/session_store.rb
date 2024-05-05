# Rails.application.config.session_store :redis_store, {
#   servers: [
#     {
#       host: "vimemo-redis.fly.dev",
#       port: 6379,  # Redisサーバーのポート
#       db: 0,
#       password: "your_redis_password",  # Redisのパスワード
#       namespace: "session"
#     },
#   ],
#   expire_after: 90.minutes,  # セッションの有効期限
#   key: "_#{Rails.application.class.module_parent_name.downcase}_session",
#   threadsafe: true,
#   secure: Rails.env.production?
# }
