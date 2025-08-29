module EndOfLife
  class Product < Data.define(:name)
    def label = name.capitalize
    def to_s = label
  end
end
