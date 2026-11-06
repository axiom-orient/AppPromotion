#if canImport(SwiftUI)
import AppPromotion
import Foundation
import SwiftUI

/// Wrap the existing List/ScrollView, then conditionally insert a row from the optional card.
@MainActor
public struct PromotionTimeline<Content: View>: View {
    private let rotation: PromotionRotation?
    private let content: (PromotionCard?) -> Content

    public init(rotation: PromotionRotation, @ViewBuilder content: @escaping (PromotionCard?) -> Content) {
        self.rotation = rotation
        self.content = content
    }

    init(optionalRotation: PromotionRotation?, @ViewBuilder content: @escaping (PromotionCard?) -> Content) {
        self.rotation = optionalRotation
        self.content = content
    }

    public var body: some View {
        TimelineView(Schedule(rotation: rotation)) { context in
            content(rotation?.card(at: context.date))
        }
    }

    private struct Schedule: TimelineSchedule {
        let rotation: PromotionRotation?

        func entries(from startDate: Date, mode: Mode) -> Entries {
            Entries(rotation: rotation, nextDate: startDate)
        }

        struct Entries: Sequence, IteratorProtocol {
            let rotation: PromotionRotation?
            var nextDate: Date?

            mutating func next() -> Date? {
                guard let date = nextDate else { return nil }
                nextDate = rotation?.nextUpdate(after: date)
                return date
            }
        }
    }
}
#endif
