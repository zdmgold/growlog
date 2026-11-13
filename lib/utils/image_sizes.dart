/// Decode widths, in pixels, for photos shown on screen. A photo from the
/// gallery can be 12 megapixels; decoding it at full size just to show a
/// small card wastes tens of megabytes. These are generous for sharp screens.
/// The full-screen zoom viewer deliberately does not use any of these.
class ImageSizes {
  /// Cards, tiles and list thumbnails.
  static const int thumb = 600;

  /// Half-width images such as the growth strip and before/after.
  static const int medium = 700;

  /// A photo that spans the screen width inside a page.
  static const int fullWidth = 1200;

  /// A photo that fills the whole screen behind other content.
  static const int hero = 1500;
}
