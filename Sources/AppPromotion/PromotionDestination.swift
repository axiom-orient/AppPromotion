import Foundation

/// A static, publisher-approved HTTPS link. It is opened only after a person's explicit action.
public struct PromotionDestination: Equatable, Sendable {
    public enum ConfigurationError: Error, Equatable, Sendable { case invalidURL }
    public let url: URL
    public var isAppStore: Bool { url.host?.lowercased() == "apps.apple.com" }

    public init(url: URL) throws {
        let raw = url.absoluteString
        guard raw.utf8.count <= 2048,
              let decoded = raw.removingPercentEncoding,
              !decoded.contains("\\"),
              decoded.rangeOfCharacter(from: .controlCharacters) == nil,
              !decoded.unicodeScalars.contains(where: { $0.properties.generalCategory == .format }),
              var parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme?.lowercased() == "https", let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil,
              parts.port == nil || parts.port == 443 else {
            throw ConfigurationError.invalidURL
        }
        parts.scheme = "https"
        parts.host = host.lowercased()
        guard let normalized = parts.url else { throw ConfigurationError.invalidURL }
        self.url = normalized
    }
}
