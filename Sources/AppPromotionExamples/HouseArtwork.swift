#if os(iOS)
import AppPromotion
import Foundation
import ImageIO
import SwiftUI

/// Genuine app icons copied from their native AppIcon sets; never fetched from a third party.
@MainActor
public enum PromotionPreviewArtwork {
    public static func icon(for app: PromotionAppID) -> Image? { icons[app] }

    private static let icons: [PromotionAppID: Image] = {
        var result: [PromotionAppID: Image] = [:]
        for app in [PromotionAppID.sumday, .daypage, .caseboard] {
            guard let url = Bundle.module.url(forResource: app.rawValue, withExtension: "png"),
                  let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: 144,
                    kCGImageSourceCreateThumbnailWithTransform: true
                  ] as CFDictionary) else { continue }
            result[app] = Image(decorative: image, scale: 3)
        }
        return result
    }()
}
#endif
