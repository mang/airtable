require "json"

module Airtable

  class ImageThumbnail
    JSON.mapping(
      url: String?,
      width: Int32?,
      height: Int32?
    )
  end

  class ImageThumbnailList
    JSON.mapping(
      small: ImageThumbnail?,
      large: ImageThumbnail?,
      full: ImageThumbnail?
    )
  end

  class Image
    JSON.mapping(
      id: String?,
      url: String?,
      filename: String?,
      size: Int32?,
      type: String?,
      thumbnails: ImageThumbnailList?,
    )
  end

end
