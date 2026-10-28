//
//  JointAccountOperationPlate.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

/// One unfinished operation of a joint account, as the main screen states it. An account can hold several at once,
/// so the caller places each plate itself.
struct JointAccountOperationPlate: View {
    let viewData: ViewData

    var body: some View {
        banner
    }

    /// Built in one expression: the banner's modifiers are its own, not `View`'s, so returning it as `some View`
    /// first would put them out of reach.
    private var banner: some View {
        let banner = MessageBanner(title: viewData.title, description: viewData.subtitle)
            .glowRing(.warning)
            .slotEnd {
                JointAccountSignatureProgressRing(
                    collectedCount: viewData.collectedSignaturesCount,
                    requiredCount: viewData.requiredSignaturesCount
                )
            }

        // Left without a tap rather than disabled: a plate waiting on the others is stated at full strength
        return viewData.isActionable ? banner.onTap(viewData.onTap) : banner
    }
}

// MARK: - Auxiliary types

extension JointAccountOperationPlate {
    struct ViewData: Identifiable {
        let id: String
        let title: String
        /// Amount and destination; the copy carries the arrow between them.
        let subtitle: String
        let collectedSignaturesCount: Int
        let requiredSignaturesCount: Int
        /// Whether this member is the one holding the operation up — the only case that opens it.
        let isActionable: Bool
        let onTap: () -> Void
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 8) {
        JointAccountOperationPlate(
            viewData: JointAccountOperationPlate.ViewData(
                id: "operation-awaiting-others",
                title: Localization.jointOperationBannerTitle("Jacob", "Ethereum"),
                subtitle: Localization.jointOperationBannerSubtitle("0.5 ETH", "0xBef7…A9cE"),
                collectedSignaturesCount: 1,
                requiredSignaturesCount: 3,
                isActionable: false,
                onTap: {}
            )
        )

        JointAccountOperationPlate(
            viewData: JointAccountOperationPlate.ViewData(
                id: "operation-awaiting-me",
                title: Localization.jointOperationBannerTitle("Isaac", "Ethereum"),
                subtitle: Localization.jointOperationBannerSubtitle("1.5 ETH", "0x1F98…F984"),
                collectedSignaturesCount: 2,
                requiredSignaturesCount: 3,
                isActionable: true,
                onTap: {}
            )
        )
    }
    .padding(12)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
