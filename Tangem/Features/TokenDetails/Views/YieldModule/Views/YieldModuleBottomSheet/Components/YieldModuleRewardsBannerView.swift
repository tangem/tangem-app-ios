//
//  YieldModuleRewardsBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct YieldModuleRewardsBannerView: View {
    let viewData: ViewData
    let claimAction: () -> Void

    var body: some View {
        banner.slotEnd { claimButton }
    }

    private var banner: MessageBanner<EmptyView, EmptyView, EmptyView> {
        MessageBanner(title: viewData.title, description: viewData.subtitle)
            .variant(.info)
            .glowRing(.info)
    }

    private var claimButton: some View {
        TangemUI.Button(
            label: Localization.commonClaim,
            accessibilityLabel: Localization.commonClaim,
            action: claimAction
        )
        .styleType(.default)
        .size(.x9)
        .disabled(viewData.claimAvailability == .disabled)
    }
}

// MARK: - View Data

extension YieldModuleRewardsBannerView {
    struct ViewData: Equatable {
        enum ClaimAvailability: Equatable {
            case available
            case disabled
        }

        let title: String
        let subtitle: String
        let claimAvailability: ClaimAvailability
    }
}
