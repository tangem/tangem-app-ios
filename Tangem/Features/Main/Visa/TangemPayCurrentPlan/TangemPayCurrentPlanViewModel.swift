//
//  TangemPayCurrentPlanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemLocalization
import TangemPay

final class TangemPayCurrentPlanViewModel: ObservableObject {
    let planName: String
    let sections: [Section]
    let changePlanButtonTitle: String

    @Published private(set) var downgradeBanner: DowngradeBanner?

    private weak var coordinator: TangemPayCurrentPlanRoutable?

    init(
        customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan,
        customerTariffPlanPublisher: AnyPublisher<VisaCustomerInfoResponse.CustomerTariffPlan?, Never>,
        coordinator: TangemPayCurrentPlanRoutable? = nil
    ) {
        self.coordinator = coordinator

        let tariffPlan = customerTariffPlan.tariffPlan
        planName = tariffPlan.name
        sections = Self.makeSections(from: tariffPlan.descriptionItems)
        downgradeBanner = Self.makeDowngradeBanner(from: customerTariffPlan)

        changePlanButtonTitle = Localization.tangempayCurrentPlanChange

        customerTariffPlanPublisher
            .map { $0.flatMap(Self.makeDowngradeBanner(from:)) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$downgradeBanner)
    }

    func changePlan() {
        Analytics.log(.visaTiersChangePlanClicked)
        coordinator?.openSelectPlan()
    }

    func stayOnPlus() {
        guard let downgradeBanner else {
            return
        }

        Analytics.log(.visaTiersStayOnPlusConditionsClicked)

        coordinator?.openStayOnPlusConfirmation(
            planName: downgradeBanner.planName,
            pendingPlanName: downgradeBanner.pendingPlanName
        )
    }
}

// MARK: - Mapping

private extension TangemPayCurrentPlanViewModel {
    static let downgradeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static func makeDowngradeBanner(
        from customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan
    ) -> DowngradeBanner? {
        guard
            customerTariffPlan.status == .downgradePending,
            let pendingPlan = customerTariffPlan.pendingTariffPlan,
            let nextBillingAt = customerTariffPlan.nextBillingAt
        else {
            return nil
        }

        let planName = customerTariffPlan.tariffPlan.name
        let fee = customerTariffPlan.tariffPlan.fees
            .first { $0.type == .recurring }
            .map { BalanceFormatter().formatFiatBalance($0.amount, currencyCode: $0.currency) } ?? ""

        let text = Localization.tangempayCurrentPlanActiveTillNotification(
            planName,
            downgradeDateFormatter.string(from: nextBillingAt),
            pendingPlan.name,
            fee
        )

        return DowngradeBanner(text: text, planName: planName, pendingPlanName: pendingPlan.name)
    }

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
    func openStayOnPlusConfirmation(planName: String, pendingPlanName: String)
}

extension TangemPayCurrentPlanViewModel {
    struct DowngradeBanner: Equatable {
        let text: String
        let planName: String
        let pendingPlanName: String
    }

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
