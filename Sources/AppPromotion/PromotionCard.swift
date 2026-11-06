import Foundation

/// Stable application key chosen by the publisher, never a user or installation identifier.
public struct PromotionAppID: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer()
        let raw = try value.decode(String.self)
        guard Self.valid(raw) else {
            throw DecodingError.dataCorruptedError(in: value, debugDescription: "Invalid application key")
        }
        rawValue = raw
    }

    public func encode(to encoder: any Encoder) throws {
        var value = encoder.singleValueContainer()
        try value.encode(rawValue)
    }

    static func valid(_ value: String) -> Bool {
        (1...128).contains(value.utf8.count) && value.utf8.allSatisfy {
            (97...122).contains($0) || (48...57).contains($0) || [45, 46, 95].contains($0)
        }
    }
}

/// App-owned display name and optional verified destination. Remote catalogs cannot replace them.
public struct PromotionTarget: Equatable, Sendable {
    public enum ConfigurationError: Error, Equatable, Sendable {
        case invalidAppID, invalidTitle, invalidAppStoreID
    }

    public let id: PromotionAppID
    public let title: String
    public let appStoreURL: URL?

    public init(id: PromotionAppID, title: String, appStoreID: String? = nil) throws {
        guard PromotionAppID.valid(id.rawValue) else { throw ConfigurationError.invalidAppID }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, title.count <= 60,
              title.rangeOfCharacter(from: .controlCharacters.union(.newlines)) == nil,
              !title.unicodeScalars.contains(where: { $0.properties.generalCategory == .format })
        else { throw ConfigurationError.invalidTitle }
        self.id = id
        self.title = title
        if let appStoreID {
            guard (1...20).contains(appStoreID.utf8.count),
                  appStoreID.utf8.allSatisfy({ (48...57).contains($0) }),
                  appStoreID.first != "0", let url = URL(string: "https://apps.apple.com/app/id" + appStoreID)
            else { throw ConfigurationError.invalidAppStoreID }
            appStoreURL = url
        } else {
            appStoreURL = nil
        }
    }
}

public struct PromotionAsset: Codable, Equatable, Sendable {
    public enum ReferenceError: Error, Sendable { case invalidReference }
    public let path: String
    public let sha256: String

    public init(path: String, sha256: String) throws {
        guard sha256.utf8.count == 64,
              sha256.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }),
              path == "/v2/assets/" + sha256 + ".png" || path == "/v2/assets/" + sha256 + ".jpg"
        else { throw ReferenceError.invalidReference }
        self.path = path; self.sha256 = sha256
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(path: values.decode(String.self, forKey: .path),
                      sha256: values.decode(String.self, forKey: .sha256))
    }

    private enum CodingKeys: String, CodingKey { case path, sha256 }
}

/// Display values only. The card's identity and destination remain fixed during an interaction.
public struct PromotionCard: Equatable, Sendable, Identifiable {
    public let id: String
    public let target: PromotionAppID
    public let title: String
    public let description: String
    public let appStoreURL: URL?
    public let icon: PromotionAsset?

    public static func read(_ data: Data, host: PromotionAppID, targets: [PromotionTarget],
                            language: String, now: Date) -> Self? {
        guard let catalog = try? PromotionCatalog(data: data) else { return nil }
        return catalog.rotation(host: host, targets: targets, language: language).card(at: now)
    }
}
