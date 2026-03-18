module EndOfLife
  module Product::Registry
    def scans_for(product_name, label: nil, aliases: [])
      product = Product.new(
        product_name,
        version_detector_for(product_name),
        label
      )

      [product_name, *aliases].each { |key| product_registry[key.to_sym.downcase] = product }
    end

    def find_product(name) = product_registry.fetch(name.to_sym.downcase)

    def products = product_registry.values.uniq
    def products_pattern(suffix: nil) = /\A(?:#{product_registry.keys.join("|")})#{suffix}/i

    private

    def product_registry
      @product_registry ||= {}
    end

    def version_detector_for(product) = VersionDetectors.for_product(product)
  end
end
