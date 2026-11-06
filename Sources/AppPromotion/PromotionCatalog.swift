import Foundation

/// Immutable catalog. Selection owns dates; adapters own retrieval and freshness.
public struct PromotionCatalog: Sendable {
    public enum ReadError: Error, Equatable, Sendable {
        case sizeLimit, malformed, unsupportedSchema, invalidRevision, campaignLimit, duplicateCampaignID
    }

    public let revision: String
    public let validUntil: Date
    public let schemaVersion: Int
    private let enabled: Bool
    private let campaigns: [Campaign]

    public init(data: Data) throws {
        guard data.count <= 32 * 1024 else { throw ReadError.sizeLimit }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload: Payload
        do { payload = try decoder.decode(Payload.self, from: data) }
        catch { throw ReadError.malformed }
        guard [2, 3].contains(payload.schemaVersion) else { throw ReadError.unsupportedSchema }
        guard Self.validRevision(payload.revision) else { throw ReadError.invalidRevision }
        guard payload.campaigns.count <= 12 else { throw ReadError.campaignLimit }
        guard Set(payload.campaigns.map(\.id)).count == payload.campaigns.count else {
            throw ReadError.duplicateCampaignID
        }
        revision = payload.revision; enabled = payload.enabled; validUntil = payload.validUntil
        schemaVersion = payload.schemaVersion
        campaigns = payload.campaigns.filter {
            PromotionAppID.valid($0.id) && PromotionAppID.valid($0.host) && PromotionAppID.valid($0.target)
                && $0.startsAt < $0.endsAt && Self.validCopy($0.description.ko) && Self.validCopy($0.description.en)
        }
    }

    /// Local registry fixes names and destinations; only campaign content comes from the catalog.
    public func rotation(host: PromotionAppID, targets: [PromotionTarget], language: String,
                         notAfter: Date? = nil, notBefore: Date? = nil) -> PromotionRotation {
        let uniqueRegistry = Set(targets.map(\.id)).count == targets.count
        let entries = campaigns.compactMap { campaign -> PromotionRotation.Entry? in
            guard campaign.host == host.rawValue, campaign.target != host.rawValue,
                  let target = targets.first(where: { $0.id.rawValue == campaign.target }) else { return nil }
            return .init(card: PromotionCard(id: campaign.id, target: target.id, title: target.title,
                description: campaign.description.text(language: language),
                destination: target.destination, icon: campaign.icon),
                startsAt: campaign.startsAt, endsAt: campaign.endsAt)
        }
        return makeRotation(host: host, permitted: schemaVersion == 2 && uniqueRegistry,
                            entries: entries, notAfter: notAfter, notBefore: notBefore)
    }

    /// Explicitly trust the selected v3 catalog operator to approve titles and destinations.
    /// This path never falls back to the v2 local registry.
    public func rotation(host: PromotionAppID, language: String,
                         notAfter: Date? = nil, notBefore: Date? = nil) -> PromotionRotation {
        let entries = campaigns.compactMap { campaign -> PromotionRotation.Entry? in
            guard campaign.host == host.rawValue, campaign.target != host.rawValue,
                  let title = campaign.title, Self.validCopy(title.ko), Self.validCopy(title.en),
                  let raw = campaign.destination, let url = URL(string: raw),
                  let destination = try? PromotionDestination(url: url) else { return nil }
            return .init(card: PromotionCard(id: campaign.id, target: .init(rawValue: campaign.target),
                title: title.text(language: language), description: campaign.description.text(language: language),
                destination: destination, icon: campaign.icon),
                startsAt: campaign.startsAt, endsAt: campaign.endsAt)
        }
        return makeRotation(host: host, permitted: schemaVersion == 3, entries: entries,
                            notAfter: notAfter, notBefore: notBefore)
    }

    private func makeRotation(host: PromotionAppID, permitted: Bool, entries: [PromotionRotation.Entry],
                              notAfter: Date?, notBefore: Date?) -> PromotionRotation {
        let validBounds = (notAfter?.timeIntervalSince1970.isFinite ?? true)
            && (notBefore?.timeIntervalSince1970.isFinite ?? true)
        return PromotionRotation(enabled: enabled && permitted && validBounds && PromotionAppID.valid(host.rawValue),
            validFrom: notBefore, validUntil: min(validUntil, notAfter ?? validUntil), entries: entries)
    }

    private static func validRevision(_ value: String) -> Bool {
        (1...64).contains(value.utf8.count) && value.utf8.allSatisfy {
            (97...122).contains($0) || (48...57).contains($0) || $0 == 45
        }
    }

    private static func validCopy(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && value.count <= 60
            && !value.contains("<") && !value.contains(">")
            && value.rangeOfCharacter(from: CharacterSet.controlCharacters.union(.newlines)) == nil
            && !value.unicodeScalars.contains { $0.properties.generalCategory == .format }
    }

    private struct Payload: Decodable {
        let schemaVersion: Int
        let revision: String
        let enabled: Bool
        let validUntil: Date
        let campaigns: [Campaign]
    }

    private struct Campaign: Decodable, Sendable {
        struct Copy: Decodable, Sendable {
            let ko: String; let en: String
            func text(language: String) -> String {
                Locale(identifier: language).language.languageCode?.identifier == "ko" ? ko : en
            }
        }
        let id: String
        let host: String
        let target: String
        let startsAt: Date
        let endsAt: Date
        let description: Copy
        let icon: PromotionAsset?
        let title: Copy?
        let destination: String?

        private enum CodingKeys: String, CodingKey {
            case id, host, target, startsAt, endsAt, description, icon, title, destination
        }

        init(from decoder: any Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            id = try values.decode(String.self, forKey: .id)
            host = try values.decode(String.self, forKey: .host)
            target = try values.decode(String.self, forKey: .target)
            startsAt = try values.decode(Date.self, forKey: .startsAt)
            endsAt = try values.decode(Date.self, forKey: .endsAt)
            description = try values.decode(Copy.self, forKey: .description)
            // A bad optional image reference must not remove a valid text advertisement.
            icon = try? values.decodeIfPresent(PromotionAsset.self, forKey: .icon)
            title = try? values.decodeIfPresent(Copy.self, forKey: .title)
            destination = try? values.decodeIfPresent(String.self, forKey: .destination)
        }
    }
}

public struct PromotionRotation: Sendable {
    fileprivate struct Entry: Sendable {
        let card: PromotionCard
        let startsAt: Date
        let endsAt: Date
    }
    fileprivate let enabled: Bool
    fileprivate let validFrom: Date?
    fileprivate let validUntil: Date
    fileprivate let entries: [Entry]

    public func card(at date: Date) -> PromotionCard? {
        guard date.timeIntervalSince1970.isFinite, enabled, date < validUntil,
              validFrom.map({ date >= $0 }) ?? true else { return nil }
        let active = entries.filter { $0.startsAt <= date && date < $0.endsAt }
        guard !active.isEmpty, Set(active.map(\.card.target)).count == active.count else { return nil }
        let index = Int(floor(date.timeIntervalSince1970 / 60)
            .truncatingRemainder(dividingBy: Double(active.count)))
        return active[index < 0 ? index + active.count : index].card
    }

    public func nextUpdate(after date: Date) -> Date? {
        let seconds = date.timeIntervalSince1970
        guard seconds.isFinite, enabled, date < validUntil, !entries.isEmpty else { return nil }
        if let validFrom, date < validFrom { return validFrom < validUntil ? validFrom : nil }
        var next = validUntil
        for entry in entries {
            if entry.startsAt > date { next = min(next, entry.startsAt) }
            if entry.endsAt > date { next = min(next, entry.endsAt) }
        }
        let active = entries.filter { $0.startsAt <= date && date < $0.endsAt }
        if active.count > 1, Set(active.map(\.card.target)).count == active.count {
            let minute = Date(timeIntervalSince1970: (floor(seconds / 60) + 1) * 60)
            if minute > date { next = min(next, minute) }
        }
        return next > date ? next : nil
    }
}
