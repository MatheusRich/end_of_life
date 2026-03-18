# frozen_string_literal: true

require "spec_helper"

RSpec.describe EndOfLife::Product::Registry do
  subject(:registry) do
    mod = Module.new { extend EndOfLife::Product::Registry }

    mod.scans_for(:nodejs, label: "Node.js", aliases: [:node])
    mod.scans_for(:ruby)

    mod
  end

  describe "#find_product" do
    it "resolves an alias to the canonical product" do
      expect(registry.find_product(:node)).to eq(registry.find_product(:nodejs))
    end

    it "finds a product by its canonical name" do
      product = registry.find_product(:ruby)

      expect(product.name).to eq("ruby")
    end

    it "raises KeyError for unknown names" do
      expect { registry.find_product(:unknown) }.to raise_error(KeyError)
    end
  end

  describe "#products_pattern" do
    it "matches both alias and canonical names" do
      pattern = registry.products_pattern

      expect("node").to match(pattern)
      expect("nodejs").to match(pattern)
      expect("ruby").to match(pattern)
      expect("unknown").not_to match(pattern)
    end

    it "matches alias with suffix" do
      pattern = registry.products_pattern(suffix: "@")

      expect("node@").to match(pattern)
      expect("nodejs@").to match(pattern)
    end
  end

  describe "#products" do
    it "returns no duplicates for aliased products" do
      expect(registry.products.map(&:name)).to eq(%w[nodejs ruby])
    end
  end
end
