module EndOfLife
  module Product
    class Release < Data.define(:product, :version, :eol_date)
      include Comparable

      def self.ruby(version, eol_date: nil) = new(product: "ruby", version:, eol_date:)

      def initialize(product:, version:, eol_date: nil)
        super(product:, eol_date:, version: Gem::Version.new(version))
      end

      ZERO = Gem::Version.new("0")
      def zero? = version == ZERO

      def eol?(at: Date.today)
        if eol_date
          eol_date <= at
        else
          self <= RubyVersion.latest_eol(at: at)
        end
      end

      def <=>(other) = version <=> other.version
      def to_s = version.to_s
    end
  end
end
