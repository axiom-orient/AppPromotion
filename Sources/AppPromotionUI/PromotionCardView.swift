#if canImport(SwiftUI)
import AppPromotion
import Foundation
import SwiftUI

/// Shared native composition; semantic fonts/colors still come from each app's design owner.
@MainActor
public struct PromotionCardView: View {
    public struct Style {
        let ink: Color
        let secondaryInk: Color
        let surface: Color
        let rule: Color
        let accent: Color
        let title: Font
        let body: Font
        let caption: Font
        let inset: CGFloat
        let radius: CGFloat

        public init(ink: Color, secondaryInk: Color, surface: Color, rule: Color, accent: Color,
                    title: Font, body: Font, caption: Font, inset: CGFloat, radius: CGFloat) {
            self.ink = ink; self.secondaryInk = secondaryInk; self.surface = surface; self.rule = rule
            self.accent = accent; self.title = title; self.body = body; self.caption = caption
            self.inset = inset; self.radius = radius
        }

        public static var standard: Self {
            Self(ink: .primary, secondaryInk: .secondary, surface: .secondary.opacity(0.08),
                 rule: .secondary.opacity(0.15), accent: .accentColor,
                 title: .headline, body: .subheadline, caption: .caption,
                 inset: 16, radius: 16)
        }
    }

    /// A live placement requires both explicit open and information/report entry actions.
    public enum Presentation {
        case preview
        case advertisement(open: (PromotionCard) -> Void, about: (PromotionCard) -> Void)
    }

    private let card: PromotionCard
    private let language: String
    private let style: Style
    private let presentation: Presentation
    private let icon: Image?

    public init(card: PromotionCard, language: String, style: Style,
                presentation: Presentation, icon: Image? = nil) {
        self.card = card
        self.language = Locale(identifier: language).language.languageCode?.identifier ?? "en"
        self.style = style
        self.presentation = presentation; self.icon = icon
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let icon {
                icon.resizable().scaledToFit()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(verbatim: card.title)
                        .font(style.title).foregroundStyle(style.ink)
                    Text(verbatim: adAttribution)
                        .font(style.caption).foregroundStyle(style.secondaryInk)
                }
                Text(verbatim: card.description)
                    .font(style.body).foregroundStyle(style.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if case let .advertisement(open, about) = presentation {
                VStack(spacing: 0) {
                    if card.destinationURL != nil {
                        Button { open(card) } label: {
                            Text(verbatim: actionTitle)
                                .font(style.caption.weight(.semibold))
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .foregroundStyle(style.accent)
                        .accessibilityLabel(Text(verbatim: card.title
                            + ", " + actionDescription))
                    }
                    Button { about(card) } label: {
                        Image(systemName: "ellipsis").frame(minWidth: 44, minHeight: 44)
                    }
                    .foregroundStyle(style.secondaryInk)
                    .accessibilityLabel(Text(verbatim: informationTitle))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(style.inset)
        .background(style.surface, in: RoundedRectangle(cornerRadius: style.radius))
        .overlay {
            RoundedRectangle(cornerRadius: style.radius).strokeBorder(style.rule, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
    }

    private var adAttribution: String {
        switch (presentation, language) {
        case (.preview, "ko"): "광고 · 시안"
        case (.preview, "ja"): "広告 · プレビュー"
        case (.preview, _): "Ad · Preview"
        case (.advertisement, "ko"): "광고"
        case (.advertisement, "ja"): "広告"
        case (.advertisement, _): "Ad"
        }
    }

    private var actionTitle: String {
        switch language {
        case "ko": "보기"
        case "ja": "見る"
        default: "View"
        }
    }

    private var actionDescription: String {
        switch (card.destination?.isAppStore == true, language) {
        case (true, "ko"): "App Store에서 보기"
        case (true, "ja"): "App Storeで見る"
        case (true, _): "view on the App Store"
        case (false, "ko"): "웹사이트 열기"
        case (false, "ja"): "ウェブサイトを開く"
        case (false, _): "open website"
        }
    }

    private var informationTitle: String {
        switch language {
        case "ko": "광고 정보와 신고"
        case "ja": "広告の詳細と報告"
        default: "Ad information and reporting"
        }
    }
}

#endif
