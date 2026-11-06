#if canImport(SwiftUI)
import AppPromotion
import AppPromotionRemote
import Foundation
import SwiftUI

/// Wrap the existing screen and insert the optional advertisement as an actual row.
/// This boundary owns only transient ad retrieval; it never touches the app's Store or records.
@MainActor
public struct PromotionPlacement<Content: View>: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @State private var loaded: Loaded?

    private let configuration: PromotionConfiguration
    private let isEnabled: Bool
    private let style: PromotionCardView.Style
    private let about: (PromotionCard) -> Void
    private let onFailure: (any Error) -> Void
    private let content: (PromotionAdvertisement?) -> Content

    public init(configuration: PromotionConfiguration, isEnabled: Bool = true,
                style: PromotionCardView.Style = .standard,
                about: @escaping (PromotionCard) -> Void,
                onFailure: @escaping (any Error) -> Void,
                @ViewBuilder content: @escaping (PromotionAdvertisement?) -> Content) {
        self.configuration = configuration; self.isEnabled = isEnabled; self.style = style
        self.about = about; self.onFailure = onFailure; self.content = content
    }

    public var body: some View {
        PromotionTimeline(optionalRotation: currentRotation) { card in
            content(card.map { card in
                PromotionAdvertisement(card: card, client: client, language: locale.identifier,
                                       style: style, about: about, onFailure: onFailure)
            })
        }
        .task(id: Request(configuration: configuration, active: active)) { await receive() }
    }

    private var active: Bool { isEnabled && scenePhase == .active }
    private var client: PromotionFeedClient { PromotionFeedClient(endpoint: configuration.endpoint) }
    private var currentRotation: PromotionRotation? {
        guard active, let loaded, loaded.configuration == configuration else { return nil }
        return loaded.feed.rotation(host: configuration.host, language: locale.identifier)
    }

    private func receive() async {
        guard !Task.isCancelled else { return }
        loaded = nil
        guard active else { return }
        do {
            while !Task.isCancelled {
                let feed = try await client.fetch()
                try Task.checkCancellation()
                guard feed.catalog.schemaVersion == 3 else { throw PromotionCatalog.ReadError.unsupportedSchema }
                loaded = Loaded(configuration: configuration, feed: feed)
                let remaining = feed.expiresAt.timeIntervalSinceNow
                guard remaining > 0 else { return }
                // Renew only a successful live lease, never a failed request or expired catalog.
                try await Task.sleep(for: .seconds(remaining))
                try Task.checkCancellation()
                loaded = nil
                guard Date() < feed.catalog.validUntil else { return }
            }
        } catch {
            guard !Task.isCancelled else { return }
            loaded = nil
            onFailure(error)
        }
    }

    private struct Loaded {
        let configuration: PromotionConfiguration
        let feed: PromotionFeed
    }
    private struct Request: Equatable {
        let configuration: PromotionConfiguration
        let active: Bool
    }
}

/// The exact selected card with its optional verified icon and system HTTPS action.
/// Created by PromotionPlacement; adding this value to the host layout adds one ad row.
@MainActor
public struct PromotionAdvertisement: View {
    public let card: PromotionCard
    fileprivate let client: PromotionFeedClient
    fileprivate let language: String
    fileprivate let style: PromotionCardView.Style
    fileprivate let about: (PromotionCard) -> Void
    fileprivate let onFailure: (any Error) -> Void

    @Environment(\.openURL) private var openURL
    @State private var artwork: Artwork?

    public enum InteractionError: Error, Sendable { case destinationNotOpened }

    fileprivate init(card: PromotionCard, client: PromotionFeedClient, language: String,
                     style: PromotionCardView.Style, about: @escaping (PromotionCard) -> Void,
                     onFailure: @escaping (any Error) -> Void) {
        self.card = card; self.client = client; self.language = language; self.style = style
        self.about = about; self.onFailure = onFailure
    }

    public var body: some View {
        PromotionCardView(card: card, language: language, style: style,
                          presentation: .advertisement(open: open, about: about),
                          icon: artwork.flatMap { $0.asset == card.icon ? $0.image : nil })
            .task(id: card.icon) { await receiveArtwork() }
    }

    private func open(_ displayed: PromotionCard) {
        guard let destination = displayed.destinationURL else { return }
        openURL(destination) { accepted in
            if !accepted { onFailure(InteractionError.destinationNotOpened) }
        }
    }

    private func receiveArtwork() async {
        guard !Task.isCancelled else { return }
        artwork = nil
        guard let asset = card.icon else { return }
        do {
            let data = try await client.fetchImage(asset)
            try Task.checkCancellation()
            artwork = Artwork(asset: asset, image: try PromotionArtwork.image(data: data))
        } catch {
            // The same campaign remains a valid text card; report the omitted optional artwork.
            guard !Task.isCancelled else { return }
            onFailure(error)
        }
    }

    private struct Artwork {
        let asset: PromotionAsset
        let image: Image
    }
}
#endif
