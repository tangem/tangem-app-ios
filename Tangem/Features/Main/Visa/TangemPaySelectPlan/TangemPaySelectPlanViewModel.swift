//
//  TangemPaySelectPlanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPay

final class TangemPaySelectPlanViewModel: ObservableObject {
    let navigationTitle = Localization.tangempaySelectPlanTitle
    let comparePlansButtonTitle = Localization.tangempaySelectPlanCompare

    let plans: [Plan]

    @Published var selectedPlanID: Plan.ID?

    private weak var coordinator: TangemPaySelectPlanRoutable?

    var selectedPlan: Plan? {
        plans.first { $0.id == selectedPlanID } ?? plans.first
    }

    var selectedIndex: Int {
        plans.firstIndex { $0.id == selectedPlanID } ?? 0
    }

    var selectButtonTitle: String {
        switch selectedPlan?.transitionType {
        case .upgrade: Localization.tangempaySelectPlanBtnUpgrade
        case .downgrade: Localization.tangempaySelectPlanBtnDowngrade
        case .activation, .none: Localization.tangempaySelectPlanBtnSelect
        }
    }

    init(
        transitions: TangemPayTariffPlanTransitionsResponse,
        coordinator: TangemPaySelectPlanRoutable?
    ) {
        self.coordinator = coordinator

        plans = transitions.map { transition in
            Plan(
                id: transition.tariffPlan.id,
                name: transition.tariffPlan.name,
                transitionType: transition.type,
                points: Self.makePoints(from: transition.tariffPlan.descriptionItems)
            )
        }

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

// MARK: - Mapping

private extension TangemPaySelectPlanViewModel {
    static func makePoints(
        from items: [VisaCustomerInfoResponse.TariffPlan.DescriptionItem]
    ) -> [Point] {
        items
            .sorted { ($0.type.sortIndex, $0.order) < ($1.type.sortIndex, $1.order) }
            .map { Point(title: $0.title, subtitle: $0.body) }
    }
}

private extension VisaCustomerInfoResponse.TariffPlan.DescriptionItem.ItemType {
    var sortIndex: Int {
        switch self {
        case .cardRelated: 0
        case .planRelated: 1
        }
    }
}

// MARK: - Types

extension TangemPaySelectPlanViewModel {
    struct Plan: Identifiable {
        let id: String
        let name: String
        let transitionType: TangemPayTariffPlanTransition.TransitionType
        let points: [Point]
    }

    struct Point: Identifiable {
        let id = UUID()
        let title: String
        var subtitle: String?
    }
}

// MARK: - Routable

protocol TangemPaySelectPlanRoutable: AnyObject {
    func closeSelectPlanFlow()
    func openComparePlans()
}
