# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# Rails.application.config.assets.paths << Rails.root.join('app/assets/builds')

# 本番環境でのアセットのコピー先を指定する
Rails.application.config.assets.precompile += %w( application.css application.js )

# 本番環境でのアセットのコピー
if Rails.env.production?
  FileUtils.cp(Rails.root.join('assets/builds/application.css'), Rails.root.join('public/assets/application.css'))
  FileUtils.cp(Rails.root.join('assets/builds/application.js'), Rails.root.join('public/assets/application.js'))
end
