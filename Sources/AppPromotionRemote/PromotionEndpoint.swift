#if !os(Linux)
import Foundation
import AppPromotion

/// One public HTTPS resource. It never contains credentials or per-user request parameters.
public struct PromotionEndpoint: Sendable {
    public let url: URL

    public init(url: URL) throws {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil,
              !components.path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }),
              !components.path.contains("\\"),
              components.path.rangeOfCharacter(from: .controlCharacters) == nil else {
            throw PromotionRemoteError.invalidEndpoint
        }
        components.scheme = "https"
        components.host = host.lowercased()
        guard let normalized = components.url else { throw PromotionRemoteError.invalidEndpoint }
        self.url = normalized
    }

    func imageURL(for asset: PromotionAsset) throws -> URL {
        let digest = asset.sha256
        guard digest.utf8.count == 64,
              digest.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }),
              asset.path == "/v2/assets/\(digest).png" || asset.path == "/v2/assets/\(digest).jpg",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw PromotionRemoteError.invalidAsset
        }
        components.path = asset.path
        guard let imageURL = components.url else { throw PromotionRemoteError.invalidAsset }
        return imageURL
    }
}

public enum PromotionRemoteError: Error, Equatable, Sendable {
    case invalidEndpoint
    case invalidAsset
    case invalidResponse
    case redirectRejected
    case httpStatus(Int)
    case unexpectedContentType
    case sizeLimit(Int)
    case checksumMismatch
}
#endif
