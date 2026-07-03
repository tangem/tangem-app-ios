//
//  TangemPaySelectPlanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class TangemPaySelectPlanViewModel: ObservableObject {
    // [REDACTED_TODO_COMMENT]
    let navigationTitle = "Select plan"
    let selectButtonTitle = "Select"
    let comparePlansButtonTitle = "Compare plans"

    let plans: [Plan]

    @Published var selectedPlanID: Plan.ID?

    private weak var coordinator: TangemPaySelectPlanRoutable?

    var selectedPlan: Plan {
        plans.first { $0.id == selectedPlanID } ?? plans[0]
    }

    var selectedIndex: Int {
        plans.firstIndex { $0.id == selectedPlanID } ?? 0
    }

    init(coordinator: TangemPaySelectPlanRoutable?) {
        self.coordinator = coordinator

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        plans = [
            Plan(
                id: "basic",
                name: "Basic",
                cardStyle: .platinum,
                points: [
                    Point(title: "$10.000 daily spending limit"),
                    Point(title: "$0 / month"),
                ]
            ),
            Plan(
                id: "plus",
                name: "Plus",
                cardStyle: .signature,
                points: [
                    Point(
                        title: "Airport lounge access, travel perks",
                        subtitle: "and other Visa Signature benefits"
                    ),
                    Point(title: "$50.000 daily spending limit"),
                    Point(title: "$29.99 / month"),
                ]
            ),
        ]

        selectedPlanID = plans.first?.id
    }

    func select() {
        // [REDACTED_TODO_COMMENT]
    }

    func comparePlans() {
        coordinator?.openComparePlans()
    }

    func close() {
        coordinator?.closeSelectPlanFlow()
    }
}

// MARK: - Types

extension TangemPaySelectPlanViewModel {
    struct Plan: Identifiable {
        let id: String
        let name: String
        let cardStyle: CardStyle
        let points: [Point]
    }

    struct Point: Identifiable {
        let id = UUID()
        let title: String
        var subtitle: String?
    }

    enum CardStyle {
        case platinum
        case signature
    }
}

// MARK: - Routable

protocol TangemPaySelectPlanRoutable: AnyObject {
    func closeSelectPlanFlow()
    func openComparePlans()
}
