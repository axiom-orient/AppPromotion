#if !os(Linux)
import Foundation
import AppPromotion

/// Opt-in to an operator-managed v3 catalog. The operator approves its ads and HTTPS destinations.
public struct PromotionConfiguration: Equatable, Sendable {
    public enum ConfigurationError: Error, Equatable, Sendable { case invalidHost }
    public let endpoint: PromotionEndpoint
    public let host: PromotionAppID

    public init(catalogURL: URL, host: String) throws {
        let id = PromotionAppID(rawValue: host)
        guard id.isValid else { throw ConfigurationError.invalidHost }
        self.endpoint = try PromotionEndpoint(url: catalogURL)
        self.host = id
    }
}
#endif
