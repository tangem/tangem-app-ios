//
//  TangemPayCurrentPlanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPay

final class TangemPayCurrentPlanViewModel: ObservableObject {
    let planName: String
    let sections: [Section]
    let changePlanButtonTitle: String

    private weak var coordinator: TangemPayCurrentPlanRoutable?

    init(
        customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan,
        coordinator: TangemPayCurrentPlanRoutable? = nil
    ) {
        self.coordinator = coordinator

        let tariffPlan = customerTariffPlan.tariffPlan
        planName = tariffPlan.name
        sections = Self.makeSections(from: tariffPlan.descriptionItems)

        changePlanButtonTitle = Localization.tangempayCurrentPlanChange
    }

    func changePlan() {
        coordinator?.openSelectPlan()
    }
}

// MARK: - Mapping

private extension TangemPayCurrentPlanViewModel {
    static func makeSections(
        from items: [VisaCustomerInfoResponse.TariffPlan.DescriptionItem]
    ) -> [Section] {
        let grouped = Dictionary(grouping: items, by: \.type)
        let orderedSections: [VisaCustomerInfoResponse.TariffPlan.DescriptionItem.ItemType] = [.cardRelated, .planRelated]

        return orderedSections.compactMap { type in
            guard let sectionItems = grouped[type], !sectionItems.isEmpty else {
                return nil
            }

            let rows = sectionItems
                .sorted { $0.order < $1.order }
                .map { Row(label: $0.title, value: $0.body ?? "") }

            return Section(title: type.sectionTitle, rows: rows)
        }
    }
}

private extension VisaCustomerInfoResponse.TariffPlan.DescriptionItem.ItemType {
    var sectionTitle: String {
        switch self {
        case .cardRelated: Localization.tangempayCurrentPlanSectionCard
        case .planRelated: Localization.tangempayCurrentPlanSectionPlan
        case .onboardingRelated: ""
        }
    }
}

// MARK: - Routable

protocol TangemPayCurrentPlanRoutable: AnyObject {
    func openSelectPlan()
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
