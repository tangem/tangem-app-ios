//
//  EarnProductDetailsSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
@testable import Tangem

enum EarnProductDetailsSnapshotScenario: String, SnapshotScenario {
    case lendingOnAave
    case lendingOnAaveCompact
    case pooledStaking
    case lendingOnAaveRTL
    case lendingOnAaveLargeText
    case longValues
    case riskInfoSheet
    case withdrawalsInfoSheet
    case performanceFeeInfoSheet

    var layoutDirection: LayoutDirection {
        self == .lendingOnAaveRTL ? .rightToLeft : .leftToRight
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .lendingOnAaveLargeText ? .xxxLarge : .large
    }

    @MainActor
    var body: some View {
        content
            .frame(width: self == .lendingOnAaveCompact ? Constants.compactWidth : Constants.regularWidth)
    }
}

private extension EarnProductDetailsSnapshotScenario {
    @MainActor
    @ViewBuilder
    var content: some View {
        let details = EarnProductDetails.preview

        switch self {
        case .lendingOnAave, .lendingOnAaveCompact, .lendingOnAaveRTL, .lendingOnAaveLargeText:
            VStack(spacing: 0) {
                EarnProductBenefitsView(benefits: details.benefits)
                EarnProductDetailsView(details: details, onLinkTap: { _ in }, onInfoTap: { _ in })
            }
        case .pooledStaking:
            let stakingDetails = EarnProductDetails.pooledStaking(performanceFee: 0.08)

            VStack(spacing: 0) {
                EarnProductBenefitsView(benefits: stakingDetails.benefits)
                EarnProductDetailsView(details: stakingDetails, onLinkTap: { _ in }, onInfoTap: { _ in })
            }
        case .longValues:
            EarnProductDetailsView(details: .longValues, onLinkTap: { _ in }, onInfoTap: { _ in })
        case .riskInfoSheet:
            infoSheet(details.risk.info)
        case .withdrawalsInfoSheet:
            infoSheet(details.withdrawals.info)
        case .performanceFeeInfoSheet:
            infoSheet(details.performanceFee.info)
        }
    }

    @MainActor
    func infoSheet(_ info: EarnProductDetails.InfoSheet) -> some View {
        EarnProductInfoSheetView(sheet: info)
            .padding(.horizontal, 8)
    }
}

private extension EarnProductDetails {
    static var longValues: EarnProductDetails {
        let details = EarnProductDetails.preview

        return EarnProductDetails(
            benefits: details.benefits,
            risk: details.risk,
            provider: details.provider.map { Link(title: $0.title, name: "Aave V3 Ethereum Core Market", url: $0.url) },
            withdrawals: Detail(value: "Usually instant, subject to protocol liquidity", info: details.withdrawals.info),
            managementFee: nil,
            performanceFee: details.performanceFee,
            auditReport: details.auditReport
        )
    }
}

// MARK: - Constants

private extension EarnProductDetailsSnapshotScenario {
    enum Constants {
        static let regularWidth: CGFloat = 402
        static let compactWidth: CGFloat = 375
    }
}
