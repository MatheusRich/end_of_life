module EndOfLife
  class Product
    class Release < Data.define(:product, :version, :eol_date)
      include Comparable

      def self.parse!(string)
        product, version = string.split("@", 2)
        raise ArgumentError, "Invalid product release format: #{string}" if product.to_s.empty? || version.to_s.empty?

        begin
          new(product:, version:)
        rescue ArgumentError
          raise ArgumentError, "Malformed version number string: #{version}"
        end
      end

      def self.ruby(version, eol_date: nil) = new(product: "ruby", version:, eol_date:)

      def initialize(product:, version:, eol_date: nil)
        product = Product.find(product.to_s)
        eol_date = Date.parse(eol_date.to_s) if eol_date
        super(product:, eol_date:, version: Gem::Version.new(version))
      end

      def eol?(at: Date.today)
        if eol_date
          eol_date <= at
        else
          self <= product.latest_eol_release(at: at)
        end
      end

      def supported?(...) = !eol?(...)

      def latest_cycle_release
        product.all_releases.filter { |r| r.version.to_s.start_with?(cycle_version.to_s) }.max
      end

      def cycle_version
        Gem::Version.new(version.segments.first(2).join("."))
      end

      ZERO = Gem::Version.new("0")
      def zero? = version == ZERO

      def <=>(other) = version <=> other.version

      def to_s = "#{product.name}@#{version}"
    end
  end
end
