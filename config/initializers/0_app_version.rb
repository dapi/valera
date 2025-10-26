# frozen_string_literal: true

# Workaround for File.exists? deprecation
class << File
  alias exists? exist? if method_defined?(:exist?) && !method_defined?(:exists?)
end

# Handle missing semver file gracefully
require 'semver'
AppVersion = SemVer.find
