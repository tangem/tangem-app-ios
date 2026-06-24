//
//  TangemPayCurrentPlanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class TangemPayCurrentPlanViewModel: ObservableObject {
    let planName: String
    let sections: [Section]
    let changePlanButtonTitle: String

    init() {
        // [REDACTED_TODO_COMMENT]
        planName = "Basic"

        // [REDACTED_TODO_COMMENT]
        sections = [
            Section(
                title: "Card related",
                rows: [
                    Row(label: "Visa Programme", value: "Platinum"),
                    Row(label: "Max daily spending limit", value: "$10.000"),
                    Row(label: "FX fee", value: "1%"),
                ]
            ),
            Section(
                title: "Plan related",
                rows: [
                    Row(label: "Plan fee", value: "$0.00"),
                    Row(label: "Max cards issued", value: "3"),
                    Row(label: "Additional benefits", value: "No"),
                ]
            ),
        ]

        // [REDACTED_TODO_COMMENT]
        changePlanButtonTitle = "Change plan"
    }

    // [REDACTED_TODO_COMMENT]
    func changePlan() {}
}

extension TangemPayCurrentPlanViewModel {
    struct Section: Identifiable {
        let id = UUID()
        let title: String
        let rows: [Row]
    }

    struct Row: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }
}
