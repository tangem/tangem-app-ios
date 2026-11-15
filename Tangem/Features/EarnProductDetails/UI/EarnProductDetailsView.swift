//
//  EarnProductDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnProductDetailsView: View {
    let details: EarnProductDetails
    let onLinkTap: (URL) -> Void
    let onInfoTap: (EarnProductDetails.InfoSheet) -> Void

    @ScaledMetric private var iconSide: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            // [REDACTED_TODO_COMMENT]
            EarnProductSectionTitle(title: "More details")

            VStack(spacing: 0) {
                detailRow(title: "Risk", detail: details.risk)
                if let provider = details.provider {
                    linkRow(provider)
                }
                detailRow(title: "Withdrawals", detail: details.withdrawals)

                if let managementFee = details.managementFee {
                    detailRow(title: "Management fee", detail: managementFee)
                }

                detailRow(title: "Performance fee", detail: details.performanceFee, showsDivider: details.auditReport != nil)

                if let auditReport = details.auditReport {
                    linkRow(auditReport, showsDivider: false)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private func detailRow(title: String, detail: EarnProductDetails.Detail, showsDivider: Bool = true) -> some View {
        Row(title: title, value: detail.value)
            .overrideTextColors(RowOverrideTextColors(title: DesignSystem.Color.textSecondary))
            .titleLineLimit(nil)
            .valueLineLimit(nil)
            .showDivider(showsDivider)
            .onTap { onInfoTap(detail.info) }
            .titleAccessory {
                DesignSystem.Icons.Info.regular20.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: iconSide, height: iconSide)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .accessibilityHidden(true)
            }
    }

    private func linkRow(_ link: EarnProductDetails.Link, showsDivider: Bool = true) -> some View {
        Row(title: link.title, value: link.name)
            .overrideTextColors(RowOverrideTextColors(title: DesignSystem.Color.textSecondary))
            .titleLineLimit(nil)
            .valueLineLimit(nil)
            .showDivider(showsDivider)
            .onTap { onLinkTap(link.url) }
            .valueAccessory {
                DesignSystem.Icons.ArrowTopRight.regular20.image
                    .renderingMode(.template)
                    .resizable()
                    .flipsForRightToLeftLayoutDirection(true)
                    .frame(width: iconSide, height: iconSide)
                    .foregroundStyle(DesignSystem.Color.iconPrimary)
                    .accessibilityHidden(true)
            }
    }
}

// MARK: - Previews

#Preview {
    EarnProductDetailsView(details: .preview, onLinkTap: { _ in }, onInfoTap: { _ in })
        .background(DesignSystem.Color.bgPrimary)
}
