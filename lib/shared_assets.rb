# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'find'
require 'pathname'
require 'tempfile'

module SharedAssets
  def self.fingerprinted?(path)
    path.match?(%r{\A(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+-[0-9a-f]{8,64}(?:\.[A-Za-z0-9_-]+)+\z}) &&
      path.split('/').none? { |part| part.start_with?('.') }
  end

  # Each process keeps its own Propshaft manifest; only immutable files are shared.
  class Server
    def initialize(app, root:, cache_control:)
      require 'rack/files'
      @app = app
      @files = Rack::Files.new(root, 'cache-control' => cache_control)
    end

    def call(env)
      path = env['PATH_INFO'].to_s.delete_prefix('/assets/')
      return @app.call(env) unless env['PATH_INFO'].to_s.start_with?('/assets/') &&
                                  %w[GET HEAD].include?(env['REQUEST_METHOD']) && SharedAssets.fingerprinted?(path)

      response = @files.call(env.merge('PATH_INFO' => "/#{path}"))
      return response unless response.first == 404

      response.last.close if response.last.respond_to?(:close)
      @app.call(env)
    end
  end

  class Publisher
    def initialize(sources:, target:, manifest_source: nil, manifest_target: nil)
      raise ArgumentError, 'Asset sources and target are required' if sources.empty? || !target
      raise ArgumentError, 'Both manifest paths are required' if manifest_source.nil? != manifest_target.nil?

      @sources = sources.map { |path| Pathname.new(path).realpath }
      @target = Pathname.new(target)
      @manifest_source = manifest_source && Pathname.new(manifest_source)
      @manifest_target = manifest_target && Pathname.new(manifest_target)
    end

    def publish
      files = inventory
      # Validate the whole set before publishing anything. Existing objects never change.
      files.each { |relative, source| verify_existing!(@target.join(relative), source) }
      verify_existing!(@manifest_target, @manifest_source) if @manifest_source
      files.each { |relative, source| publish_file(source, @target.join(relative)) }
      publish_file(@manifest_source, @manifest_target) if @manifest_source
      { files: files.size, bytes: files.values.sum { |path| path.size } }
    end

    private

    def inventory
      @sources.each_with_object({}) do |root, result|
        Find.find(root.to_s) do |name|
          path = Pathname.new(name)
          raise "Asset symlink rejected: #{path.basename}" if path.symlink?
          next if path.directory? || path.basename.to_s == '.manifest.json'
          relative = path.relative_path_from(root).to_s
          raise "Non-fingerprinted asset rejected: #{relative}" unless path.file? && SharedAssets.fingerprinted?(relative)
          verify_existing!(result[relative], path) if result.key?(relative)
          result[relative] ||= path
        end
      end
    end

    def verify_existing!(destination, source)
      raise "Asset symlink rejected: #{destination.basename}" if destination.symlink?
      return unless destination.exist?
      unless destination.file? && Digest::SHA256.file(destination).hexdigest == Digest::SHA256.file(source).hexdigest
        raise "Immutable asset collision: #{destination.basename}"
      end
    end

    def publish_file(source, destination)
      if destination.exist? || destination.symlink?
        verify_existing!(destination, source)
        return
      end
      FileUtils.mkdir_p(destination.dirname, mode: 0o755)
      Tempfile.create('.asset-', destination.dirname) do |temp|
        IO.copy_stream(source, temp)
        temp.flush
        temp.fsync
        temp.chmod(0o644)
        begin
          File.link(temp.path, destination)
        rescue Errno::EEXIST
          verify_existing!(destination, source)
        end
      end
    end
  end
end
