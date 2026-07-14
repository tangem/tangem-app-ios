//
//  TangemPayComparePlansSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemPay
import TangemUI

struct TangemPayComparePlansSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let title = Localization.tangempaySelectPlanCompare
    let attributes: [Attribute]
    let plans: [ComparePlan]

    private let coordinator: TangemPayComparePlansRoutable

    init(
        transitions: TangemPayTariffPlanTransitionsResponse,
        coordinator: TangemPayComparePlansRoutable
    ) {
        self.coordinator = coordinator

        let tariffPlans = transitions.map(\.tariffPlan)
        let orderedAttributes = Self.makeOrderedAttributes(from: tariffPlans)

        attributes = orderedAttributes.map { Attribute(id: $0, tabTitle: $0) }

        plans = tariffPlans.map { plan in
            let valuesByTitle = Dictionary(
                plan.descriptionItems.map { ($0.title, $0.body) },
                uniquingKeysWith: { first, _ in first }
            )

            return ComparePlan(
                name: plan.name,
                thumbnailURL: plan.images.first { $0.type == .thumbnail }?.url,
                cells: orderedAttributes.map { valuesByTitle[$0].flatMap { $0 } ?? Constants.missingValue }
            )
        }
    }

    func close() {
        coordinator.closeComparePlans()
    }
}

// MARK: - Mapping

private extension TangemPayComparePlansSheetViewModel {
    enum Constants {
        static let missingValue = "—"
    }

    /// Distinct description-item titles across all plans, ordered card-related first, then by `order`.
    static func makeOrderedAttributes(
        from plans: [VisaCustomerInfoResponse.TariffPlan]
    ) -> [String] {
        var seen = Set<String>()
        var attributes: [(title: String, sortIndex: Int, order: Int)] = []

        for plan in plans {
            for item in plan.descriptionItems where seen.insert(item.title).inserted {
                attributes.append((item.title, item.type.sortIndex, item.order))
            }
        }

        return attributes
            .sorted { ($0.sortIndex, $0.order) < ($1.sortIndex, $1.order) }
            .map(\.title)
    }
}

private extension VisaCustomerInfoResponse.TariffPlan.DescriptionItem.ItemType {
    var sortIndex: Int {
        switch self {
        case .cardRelated: 0
        case .planRelated: 1
        case .onboardingRelated: 2
        }
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
        let thumbnailURL: String?
        let cells: [String]
    }
}

// MARK: - Routable

protocol TangemPayComparePlansRoutable: AnyObject {
    func closeComparePlans()
}
