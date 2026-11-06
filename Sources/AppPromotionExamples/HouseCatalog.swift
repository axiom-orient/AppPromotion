import AppPromotion
import Foundation

/// Optional first-party examples, not identifiers required by the reusable SDK.
public extension PromotionAppID {
    static let sumday = Self(rawValue: "sumday")
    static let daypage = Self(rawValue: "daypage")
    static let caseboard = Self(rawValue: "caseboard")
}

#if DEBUG
extension PromotionRotation {
    public static func preview(host: PromotionAppID, language: String) -> Self? {
        let apps: [PromotionAppID] = [.sumday, .daypage, .caseboard]
        guard let index = apps.firstIndex(of: host) else { return nil }
        let targetIDs = Array(apps.dropFirst(index + 1)) + Array(apps.prefix(index))
        let campaigns: [[String: Any]] = targetIDs.map { target in
            [
                "id": "\(host.rawValue)-to-\(target.rawValue)-01",
                "host": host.rawValue, "target": target.rawValue,
                "startsAt": "2020-01-01T00:00:00Z", "endsAt": "2100-01-01T00:00:00Z",
                "description": description(for: target)
            ]
        }
        let payload: [String: Any] = [
            "schemaVersion": 2, "revision": "house-preview-01", "enabled": true,
            "validUntil": "2100-01-01T00:00:00Z", "campaigns": campaigns
        ]
        do {
            let targets = try targetIDs.map {
                try PromotionTarget(id: $0, title: title(for: $0, language: language))
            }
            let snapshot = try PromotionCatalog(data: JSONSerialization.data(withJSONObject: payload))
            return snapshot.rotation(host: host, targets: targets, language: language)
        } catch { return nil }
    }

    private static func title(for app: PromotionAppID, language: String) -> String {
        switch (app, language == "ko") {
        case (.sumday, true): "섬데이"
        case (.sumday, false): "Sumday"
        case (.daypage, true): "데이페이지"
        case (.daypage, false): "DayPage"
        case (.caseboard, true): "케이스보드"
        case (.caseboard, false): "Caseboard"
        default: app.rawValue
        }
    }

    private static func description(for app: PromotionAppID) -> [String: String] {
        switch app {
        case .sumday:
            ["ko": "하루의 작은 순간을 나만의 일기에 남겨요.",
             "en": "Save the little moments in your own journal."]
        case .daypage:
            ["ko": "사진과 메모로 하루를 한 장에 담아요.",
             "en": "Make a page from a day's photos and notes."]
        case .caseboard:
            ["ko": "흩어진 기록과 단서를 한 보드에 모아요.",
             "en": "Bring notes and clues together on one board."]
        default: [:]
        }
    }
}
#endif
