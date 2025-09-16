module EndOfLife
  module VersionDetectors
    extend self

    def for_product(product)
      detector_class = "#{self}::#{camelize(product.to_s)}"

      const_get(detector_class)
    end

    private

    def camelize(word) = Zeitwerk::Inflector.new.camelize(word, nil)
  end
end
