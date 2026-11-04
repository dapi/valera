# frozen_string_literal: true

require Rails.root.join('lib/shared_assets')

if ApplicationConfig.shared_assets_path.present?
  Rails.application.config.middleware.insert_before(
    ActionDispatch::Static, SharedAssets::Server,
    root: ApplicationConfig.shared_assets_path,
    cache_control: "public, max-age=#{ApplicationConfig.shared_asset_cache_seconds}, immutable"
  )
end

if ApplicationConfig.asset_manifest_path.present?
  Rails.application.config.assets.manifest_path = Pathname.new(ApplicationConfig.asset_manifest_path)
end
