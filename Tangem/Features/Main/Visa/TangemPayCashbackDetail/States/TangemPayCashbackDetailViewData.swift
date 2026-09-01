//
//  TangemPayCashbackDetailViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayCashbackDetailViewData {
    let header: Header
    let banner: Banner?
    let rateCard: RateCard?
    let chart: Chart
    let additionalPromotions: [AdditionalPromotion]

    var isEmpty: Bool {
        if case .empty = header {
            return true
        }

        return false
    }
}

extension TangemPayCashbackDetailViewData {
    enum Header {
        case earned(formattedAmount: String, monthName: String, payoutWindow: String?)
        case empty
    }

    enum Banner {
        case deposit(formattedAmount: String, monthName: String, payoutDate: String)
        case refund
    }

    struct RateCard {
        let title: String
        let subtitle: String?
    }

    struct Chart {
        let formattedTotal: String
        let items: [TangemPayCashbackChartView.Item]
    }

    struct AdditionalPromotion: Identifiable {
        let id: String
        let badge: Badge
        let title: String
        let subtitle: AttributedString?

        struct Badge {
            let label: String
            let isTimeLimited: Bool
        }
    }
}

// MARK: - Previews

#if DEBUG
extension TangemPayCashbackDetailViewData {
    static func makePreview(
        header: Header = .earned(formattedAmount: "$32.15", monthName: "June", payoutWindow: "July 1 – 5"),
        banner: Banner? = .deposit(formattedAmount: "$32.15", monthName: "June", payoutDate: "July 5"),
        rateCard: RateCard? = .previewSingleTier,
        chart: Chart = .preview,
        additionalPromotions: [AdditionalPromotion] = previewPromotions
    ) -> TangemPayCashbackDetailViewData {
        TangemPayCashbackDetailViewData(
            header: header,
            banner: banner,
            rateCard: rateCard,
            chart: chart,
            additionalPromotions: additionalPromotions
        )
    }

    static let preview = makePreview()

    static let previewMultipleTiers = makePreview(rateCard: .previewMultipleTiers)

    static let previewWithoutPromotions = makePreview(additionalPromotions: [])

    static let previewWithRefund = makePreview(
        header: .earned(formattedAmount: "-$3.20", monthName: "June", payoutWindow: nil),
        banner: .refund,
        chart: .previewRefund
    )

    static let previewEmpty = makePreview(
        header: .empty,
        banner: nil,
        chart: .previewZero,
        additionalPromotions: []
    )

    static let previewPromotions = [
        AdditionalPromotion(
            id: "permanent",
            badge: .init(label: "Permanent", isTimeLimited: false),
            title: "Groceries increase",
            subtitle: previewSubtitle("+1% cashback for groceries stores")
        ),
        AdditionalPromotion(
            id: "limited",
            badge: .init(label: "Until 09.26.2026", isTimeLimited: true),
            title: "Groceries increase",
            subtitle: previewSubtitle(
                "+1% cashback at [participating stores](https://tangem.com). $10 max per month"
            )
        ),
        AdditionalPromotion(
            id: "limited-higher-rate",
            badge: .init(label: "Until 09.26.2026", isTimeLimited: true),
            title: "Cashback increase",
            subtitle: previewSubtitle("+2% cashback for groceries stores. $10 max per month")
        ),
    ]

    static func previewSubtitle(_ markdown: String) -> AttributedString {
        TangemPayCashbackDetailViewDataFactory.makeMarkdown(markdown)
    }
}

extension TangemPayCashbackDetailViewData.RateCard {
    static let previewSingleTier = Self(title: "Cashback 1%", subtitle: "With your Basic plan")
    static let previewMultipleTiers = Self(title: "Cashback up to 2%", subtitle: "With your Plus plan")
}

extension TangemPayCashbackDetailViewData.Chart {
    static let preview = Self(
        formattedTotal: "$153.01",
        items: [
            .init(month: "Feb", value: 12.02, formattedValue: "$12.02", isSelected: false),
            .init(month: "Mar", value: 44.22, formattedValue: "$44.22", isSelected: false),
            .init(month: "Apr", value: 38.52, formattedValue: "$38.52", isSelected: false),
            .init(month: "May", value: 26.10, formattedValue: "$26.10", isSelected: false),
            .init(month: "Jun", value: 32.15, formattedValue: "$32.15", isSelected: true),
        ]
    )

    static let previewRefund = Self(
        formattedTotal: "$117.66",
        items: [
            .init(month: "Feb", value: 12.02, formattedValue: "$12.02", isSelected: false),
            .init(month: "Mar", value: 44.22, formattedValue: "$44.22", isSelected: false),
            .init(month: "Apr", value: 38.52, formattedValue: "$38.52", isSelected: false),
            .init(month: "May", value: 26.10, formattedValue: "$26.10", isSelected: false),
            .init(month: "Jun", value: -3.20, formattedValue: "-$3.20", isSelected: true),
        ]
    )

    static let previewZero = Self(
        formattedTotal: "$0.00",
        items: [
            .init(month: "Feb", value: 0, formattedValue: "$0.00", isSelected: false),
            .init(month: "Mar", value: 0, formattedValue: "$0.00", isSelected: false),
            .init(month: "Apr", value: 0, formattedValue: "$0.00", isSelected: false),
            .init(month: "May", value: 0, formattedValue: "$0.00", isSelected: false),
            .init(month: "Jun", value: 0, formattedValue: "$0.00", isSelected: true),
        ]
    )
}
#endif
