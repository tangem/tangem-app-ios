//
//  TangemPayCurrentPlanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemPay
import struct TangemUIUtils.AlertBinder

final class TangemPayCurrentPlanViewModel: ObservableObject {
    let planName: String
    let sections: [Section]
    let changePlanButtonTitle: String

    @Published private(set) var isLoadingPlans = false
    @Published var alert: AlertBinder?

    private let customerService: any CustomerInfoManagementService
    private weak var coordinator: TangemPayCurrentPlanRoutable?

    init(
        customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan,
        customerService: any CustomerInfoManagementService,
        coordinator: TangemPayCurrentPlanRoutable? = nil
    ) {
        self.customerService = customerService
        self.coordinator = coordinator

        let tariffPlan = customerTariffPlan.tariffPlan
        planName = tariffPlan.name
        sections = Self.makeSections(from: tariffPlan.descriptionItems)

        changePlanButtonTitle = Localization.tangempayCurrentPlanChange
    }

    func changePlan() {
        guard !isLoadingPlans else { return }

        isLoadingPlans = true

        runTask(in: self) { @MainActor viewModel in
            do {
                let transitions = try await viewModel.customerService.getTariffPlanTransitions()

                viewModel.isLoadingPlans = false
                viewModel.coordinator?.openSelectPlan(transitions: transitions)
            } catch {
                viewModel.isLoadingPlans = false
                viewModel.alert = AlertBinder(
                    title: Localization.commonError,
                    message: Localization.commonUnknownError
                )
            }
        }
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
                .map { Row(label: $0.title, value: $0.body) }

            return Section(title: type.sectionTitle, rows: rows)
        }
    }
}

private extension VisaCustomerInfoResponse.TariffPlan.DescriptionItem.ItemType {
    var sectionTitle: String {
        switch self {
        case .cardRelated: Localization.tangempayCurrentPlanSectionCard
        case .planRelated: Localization.tangempayCurrentPlanSectionPlan
        }
    }
}

// MARK: - Routable

protocol TangemPayCurrentPlanRoutable: AnyObject {
    func openSelectPlan(transitions: TangemPayTariffPlanTransitionsResponse)
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
