#if canImport(SwiftUI)
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

@MainActor
public enum PromotionArtwork {
    public enum DecodeError: Error { case invalidImage }

    /// Call only with the exact asset bytes whose hash the transport verified.
    public static func image(data: Data) throws -> Image {
        guard data.count <= 96 * 1024,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) == 1,
              let type = CGImageSourceGetType(source) as String?,
              [UTType.png.identifier, UTType.jpeg.identifier].contains(type),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              (1...256).contains(width), (1...256).contains(height),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { throw DecodeError.invalidImage }
        return Image(decorative: image, scale: 3)
    }
}
#endif
