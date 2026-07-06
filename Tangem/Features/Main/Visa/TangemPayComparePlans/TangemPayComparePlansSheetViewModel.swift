//
//  TangemPayComparePlansSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

struct TangemPayComparePlansSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    // [REDACTED_TODO_COMMENT]
    let title = "Compare plans"
    let attributes: [Attribute]
    let plans: [ComparePlan]

    private let coordinator: TangemPayComparePlansRoutable

    init(coordinator: TangemPayComparePlansRoutable) {
        self.coordinator = coordinator

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        attributes = [
            Attribute(id: "availableCards", tabTitle: "Available cards"),
            Attribute(id: "visaProgramme", tabTitle: "Visa programme"),
            Attribute(id: "planFee", tabTitle: "Plan fee"),
            Attribute(id: "fxFee", tabTitle: "FX fee"),
            Attribute(id: "replacementFee", tabTitle: "Replacement fee"),
            Attribute(id: "dailyLimit", tabTitle: "Daily spending limit"),
            Attribute(id: "additionalBenefits", tabTitle: "Additional benefits"),
        ]

        plans = [
            ComparePlan(
                name: "Basic",
                cells: [
                    .availableCards(cardType: "Virtual", cardCount: "Up to 3"),
                    .value(primary: "Platinum", caption: nil),
                    .value(primary: "$0", caption: nil),
                    .value(primary: "1%", caption: "For non-USD purchases"),
                    .value(primary: "$1", caption: nil),
                    .value(primary: "$10,000", caption: "Per card"),
                    .value(primary: "No", caption: nil),
                ]
            ),
            ComparePlan(
                name: "Plus",
                cells: [
                    .availableCards(cardType: "Virtual", cardCount: "Up to 5"),
                    .value(primary: "Signature", caption: nil),
                    .value(primary: "$29.99/month", caption: nil),
                    .value(primary: "1%", caption: "For non-USD purchases"),
                    .value(primary: "$0", caption: nil),
                    .value(primary: "$50,000", caption: "Per card"),
                    .value(primary: "Benefit 1, Benefit 2, Benefit 3", caption: nil),
                ]
            ),
            ComparePlan(
                name: "Premium",
                cells: [
                    .availableCards(cardType: "Virtual & Physical", cardCount: "Up to 8"),
                    .value(primary: "Signature", caption: nil),
                    .value(primary: "$49.99/month", caption: nil),
                    .value(primary: "0.5%", caption: "For non-USD purchases"),
                    .value(primary: "$0", caption: nil),
                    .value(primary: "$100,000", caption: "Per card"),
                    .value(primary: "Benefit 1, Benefit 2, Benefit 3, Benefit 4", caption: nil),
                ]
            ),
            ComparePlan(
                name: "Elite",
                cells: [
                    .availableCards(cardType: "Virtual & Physical", cardCount: "Up to 12"),
                    .value(primary: "Infinite", caption: nil),
                    .value(primary: "$99.99/month", caption: nil),
                    .value(primary: "0.25%", caption: "For non-USD purchases"),
                    .value(primary: "$0", caption: nil),
                    .value(primary: "$250,000", caption: "Per card"),
                    .value(primary: "All Visa Infinite benefits", caption: nil),
                ]
            ),
            ComparePlan(
                name: "Ultimate",
                cells: [
                    .availableCards(cardType: "Virtual & Physical", cardCount: "Unlimited"),
                    .value(primary: "Infinite", caption: nil),
                    .value(primary: "$199.99/month", caption: nil),
                    .value(primary: "0%", caption: "For non-USD purchases"),
                    .value(primary: "$0", caption: nil),
                    .value(primary: "No limit", caption: "Per card"),
                    .value(primary: "Concierge, lounges, insurance & more", caption: nil),
                ]
            ),
        ]
    }

    func close() {
        coordinator.closeComparePlans()
    }
}

// MARK: - Types

extension TangemPayComparePlansSheetViewModel {
    struct Attribute: Identifiable {
        let id: String
        let tabTitle: String
    }

    struct ComparePlan: Identifiable {
        var id: String { name }
        let name: String
        let cells: [Cell]
    }

    enum Cell {
        case availableCards(cardType: String, cardCount: String)
        case value(primary: String, caption: String?)
    }
}

// MARK: - Routable

protocol TangemPayComparePlansRoutable: AnyObject {
    func closeComparePlans()
}
