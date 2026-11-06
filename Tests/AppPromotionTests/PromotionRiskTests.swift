import AppPromotion
import Foundation
import Testing

struct PromotionRiskTests {
    private let host = PromotionAppID(rawValue: "notes")
    private let start = Date(timeIntervalSince1970: 1_893_456_000) // 2030-01-01 UTC

    @Test func destinationsAndCatalogTrustStayExplicit() throws {
        let web = try PromotionDestination(url: #require(URL(string: "https://EXAMPLE.com/offer?campaign=house#details")))
        #expect(web.url.host == "example.com")
        #expect(web.url.query == "campaign=house")
        #expect(web.url.fragment == "details")
        #expect(!web.isAppStore)
        let store = try PromotionDestination(url: #require(URL(string: "https://apps.apple.com/app/id123456789")))
        #expect(store.isAppStore)
        let impostor = try PromotionDestination(url: #require(URL(string: "https://apps.apple.com.example.net/app/id123456789")))
        #expect(!impostor.isAppStore)
        for raw in [
            "http://example.com/offer", "javascript:alert(1)", "/relative", 
            "https://user:password@example.com/offer", "https://example.com:8443/offer",
            "https://example.com/%0Aoffer", "https://example.com/%5Coffer"
        ] {
            let url = try #require(URL(string: raw))
            #expect(throws: PromotionDestination.ConfigurationError.invalidURL) {
                try PromotionDestination(url: url)
            }
        }

        let local = try PromotionTarget(id: .init(rawValue: "sketch"), title: "Approved title", appStoreID: "123456789")
        let legacy = try catalog(version: 2, campaigns: [campaign()])
        let legacyCard = try #require(legacy.rotation(host: host, targets: [local], language: "ko-KR").card(at: start))
        #expect(legacyCard.title == "Approved title")
        #expect(legacyCard.appStoreURL == local.appStoreURL)
        #expect(legacyCard.destinationURL != web.url) // Remote v2 metadata never replaces local approval.
        #expect(legacyCard.description == "아이디어를 그림으로 남겨요.")
        #expect(PromotionCard.read(try data(version: 2, campaigns: [campaign()]), host: host,
                                   targets: [local], language: "ko-KR", now: start) == legacyCard)
        #expect(legacy.rotation(host: host, language: "en").card(at: start) == nil)

        let managed = try catalog(version: 3, campaigns: [campaign()])
        let managedCard = try #require(managed.rotation(host: host, language: "ko_KR").card(at: start))
        #expect(managedCard.title == "그림 앱")
        #expect(managedCard.destinationURL == web.url)
        #expect(managedCard.appStoreURL == nil)
        #expect(managed.rotation(host: host, language: "en-US").card(at: start)?.title == "Drawing app")
        #expect(managed.rotation(host: host, targets: [local], language: "en").card(at: start) == nil)

        var missing = campaign()
        missing.removeValue(forKey: "destination")
        var unsafe = campaign()
        unsafe["destination"] = "javascript:alert(1)"
        var malformedTitle = campaign()
        malformedTitle["title"] = ["ko": " ", "en": "Drawing app"]
        var selfPromotion = campaign()
        selfPromotion["target"] = host.rawValue
        for invalid in [missing, unsafe, malformedTitle, selfPromotion] {
            let rejected = try catalog(version: 3, campaigns: [invalid])
            #expect(rejected.rotation(host: host, language: "en").card(at: start) == nil)
        }
    }

    @Test func rotationRespectsLeaseAndCampaignTransitions() throws {
        let snapshot = try catalog(version: 3, campaigns: [campaign()])
        let fetchedAt = start.addingTimeInterval(10)
        let expiresAt = fetchedAt.addingTimeInterval(300)
        let rotation = snapshot.rotation(host: host, language: "en", notAfter: expiresAt, notBefore: fetchedAt)
        #expect(rotation.card(at: fetchedAt.addingTimeInterval(-1)) == nil)
        #expect(rotation.nextUpdate(after: start) == fetchedAt)
        #expect(rotation.card(at: fetchedAt)?.id == "notes-to-sketch")
        #expect(rotation.nextUpdate(after: fetchedAt) == expiresAt) // A single target needs no minute polling.
        #expect(rotation.card(at: expiresAt.addingTimeInterval(-0.001)) != nil)
        #expect(rotation.card(at: expiresAt) == nil)
        #expect(rotation.nextUpdate(after: expiresAt) == nil)

        var early = campaign()
        early["endsAt"] = timestamp(start.addingTimeInterval(45))
        let earlyRotation = try self.catalog(version: 3, campaigns: [early])
            .rotation(host: host, language: "en", notAfter: expiresAt, notBefore: fetchedAt)
        #expect(earlyRotation.nextUpdate(after: fetchedAt) == start.addingTimeInterval(45))
        #expect(earlyRotation.card(at: start.addingTimeInterval(45)) == nil)

        var upcoming = campaign()
        upcoming["startsAt"] = timestamp(start.addingTimeInterval(25))
        let future = try self.catalog(version: 3, campaigns: [upcoming])
            .rotation(host: host, language: "en", notAfter: expiresAt, notBefore: fetchedAt)
        #expect(future.card(at: fetchedAt) == nil)
        #expect(future.nextUpdate(after: fetchedAt) == start.addingTimeInterval(25))
        #expect(future.card(at: start.addingTimeInterval(25)) != nil)

        var second = campaign()
        second["id"] = "notes-to-reader"
        second["target"] = "reader"
        let rotating = try self.catalog(version: 3, campaigns: [campaign(), second])
            .rotation(host: host, language: "en", notAfter: expiresAt, notBefore: fetchedAt)
        #expect(rotating.nextUpdate(after: fetchedAt) == start.addingTimeInterval(60))
        #expect(rotating.card(at: fetchedAt)?.id != rotating.card(at: start.addingTimeInterval(60))?.id)

        second["target"] = "sketch"
        second["endsAt"] = timestamp(start.addingTimeInterval(45))
        let conflict = try self.catalog(version: 3, campaigns: [campaign(), second])
            .rotation(host: host, language: "en", notAfter: expiresAt, notBefore: fetchedAt)
        #expect(conflict.card(at: fetchedAt) == nil)
        #expect(conflict.nextUpdate(after: fetchedAt) == start.addingTimeInterval(45))
        #expect(conflict.card(at: start.addingTimeInterval(45))?.id == "notes-to-sketch")
    }

    private func campaign() -> [String: Any] {
        [
            "id": "notes-to-sketch", "host": host.rawValue, "target": "sketch",
            "startsAt": timestamp(start), "endsAt": timestamp(start.addingTimeInterval(600)),
            "description": ["ko": "아이디어를 그림으로 남겨요.", "en": "Keep an idea as a sketch."],
            "title": ["ko": "그림 앱", "en": "Drawing app"],
            "destination": "https://EXAMPLE.com/offer?campaign=house#details"
        ]
    }

    private func catalog(version: Int, campaigns: [[String: Any]]) throws -> PromotionCatalog {
        try PromotionCatalog(data: data(version: version, campaigns: campaigns))
    }

    private func data(version: Int, campaigns: [[String: Any]]) throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "schemaVersion": version, "revision": "risk-check", "enabled": true,
            "validUntil": timestamp(start.addingTimeInterval(900)), "campaigns": campaigns
        ])
    }

    private func timestamp(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
