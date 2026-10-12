//
//  TangemPayComparePlansSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization
import TangemPay
import TangemUI
import UIKit

struct TangemPayComparePlansSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let title = Localization.tangempaySelectPlanCompare
    let sections: [ComparisonSection]
    let scrollState = ScrollState()

    private let coordinator: TangemPayComparePlansRoutable

    init(
        tariffPlans: [VisaCustomerInfoResponse.TariffPlan],
        coordinator: TangemPayComparePlansRoutable
    ) {
        self.coordinator = coordinator

        let orderedAttributes = Self.makeOrderedAttributes(from: tariffPlans)

        let plansWithValues = tariffPlans.map { plan in
            let valuesByTitle = Dictionary(
                plan.descriptionItems
                    .filter { $0.type != .onboardingRelated }
                    .map { ($0.title, $0.body) },
                uniquingKeysWith: { first, _ in first }
            )
            return (name: plan.name, valuesByTitle: valuesByTitle)
        }

        sections = orderedAttributes.map { attribute in
            ComparisonSection(
                title: attribute,
                isStacked: attribute == orderedAttributes.last,
                rows: plansWithValues.map { plan in
                    let rawValue = plan.valuesByTitle[attribute].flatMap { $0 }
                    return Row(
                        planName: plan.name,
                        value: rawValue.map { TangemPayMarkdown.attributed($0, linkColor: DesignSystem.Color.textPrimary) }
                            ?? Constants.missingValue
                    )
                }
            )
        }

        Analytics.log(.visaTiersPlansComparisonPopupShowed)
    }

    func close() {
        Analytics.log(.visaTiersPlansComparisonPopupClosed)
        coordinator.closeComparePlans()
    }

    func openURL(_ url: URL) {
        coordinator.openComparePlansURL(url)
    }
}

// MARK: - Mapping

private extension TangemPayComparePlansSheetViewModel {
    enum Constants {
        static let missingValue = AttributedString("—")
    }

    /// Distinct description-item titles across all plans, ordered card-related first, then by `order`.
    static func makeOrderedAttributes(
        from plans: [VisaCustomerInfoResponse.TariffPlan]
    ) -> [String] {
        var seen = Set<String>()
        var attributes: [(title: String, sortIndex: Int, order: Int)] = []

        for plan in plans {
            for item in plan.descriptionItems where item.type != .onboardingRelated && seen.insert(item.title).inserted {
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
    struct ComparisonSection: Identifiable {
        var id: String { title }
        let title: String
        let isStacked: Bool
        let rows: [Row]
    }

    struct Row: Identifiable {
        var id: String { planName }
        let planName: String
        let value: AttributedString
    }

    final class ScrollState {
        weak var scrollView: UIScrollView?
        var pendingRestoreOffset: CGPoint?
    }
}

// MARK: - Routable

protocol TangemPayComparePlansRoutable: AnyObject {
    func closeComparePlans()
    func openComparePlansURL(_ url: URL)
}
