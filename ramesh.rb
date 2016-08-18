require 'ramesh'

module Ramesh
  class Image
    TOKYO23_GEOMETRY = "600x500+1600+700"

    def to_blob
      @image.to_blob
    end

    def scope_to_tokyo23
      @image.crop(TOKYO23_GEOMETRY)

      self
    end
  end
end
