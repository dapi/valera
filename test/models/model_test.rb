require "test_helper"

class ModelTest < ActiveSupport::TestCase
  test "fixture is valid and persisted" do
    model = models(:one)
    assert model.valid?
    assert model.persisted?
  end
end