module EndOfLife
  class Product
    class Release < Data.define(:product, :version, :eol_date)
      include Comparable

      def self.ruby(version, eol_date: nil) = new(product: "ruby", version:, eol_date:)

      def initialize(product:, version:, eol_date: nil)
        product = Product.new(product.to_s)
        eol_date = Date.parse(eol_date.to_s) if eol_date
        super(product:, eol_date:, version: Gem::Version.new(version))
      end

      def eol?(at: Date.today)
        if eol_date
          eol_date <= at
        else
          self <= product.latest_eol(at: at)
        end
      end

      ZERO = Gem::Version.new("0")
      def zero? = version == ZERO

      def <=>(other) = version <=> other.version
      def to_s = version.to_s
    end
  end
end
