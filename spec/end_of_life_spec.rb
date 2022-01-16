# frozen_string_literal: true

RSpec.describe EndOfLife do
  it "has a version number" do
    expect(EndOfLife::VERSION).not_to be nil
  end
end
