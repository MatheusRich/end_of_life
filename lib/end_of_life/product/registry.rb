module EndOfLife
  module Product::Registry
    def scans_for(product_name, label: nil)
      product_registry[product_name.to_sym.downcase] = Product.new(
        product_name,
        version_detector_for(product_name),
        label
      )
    end

    def find_product(name) = product_registry.fetch(name.to_sym.downcase)

    def products = product_registry.values
    def products_pattern(suffix: nil) = /\A(?:#{products.map(&:name).join("|")})#{suffix}/i

    private

    def product_registry
      @product_registry ||= {}
    end

    def version_detector_for(product) = VersionDetectors.for_product(product)
  end
end
