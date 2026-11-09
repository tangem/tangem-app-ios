//
//  OnrampAmountBadge.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct OnrampAmountBadge: View {
    let badge: Badge?

    var body: some View {
        switch badge {
        case .none:
            EmptyView()

        case .best:
            ZStack {
                Avatar(.icon(DesignSystem.Icons.Star.filled16, appearance: .info), size: .size16)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Localization.expressProviderBestRate)
            .accessibilityAddTraits(.isImage)

        case .loss(let percent, let signType):
            TangemUI.Badge(label: percent, accessibilityLabel: nil)
                .size(.x4)
                .appearance(signType.badgeAppearance)

        case .restricted:
            TangemUI.Badge(label: Localization.commonNotAvailable, accessibilityLabel: nil)
                .size(.x4)
        }
    }
}

extension OnrampAmountBadge {
    enum Badge: Hashable {
        case best
        case loss(percent: String, signType: ChangeSignType)
        case restricted
    }
}

private extension ChangeSignType {
    var badgeAppearance: BadgeAppearance {
        switch self {
        case .positive: .info
        case .neutral: .neutral
        case .negative: .error
        }
    }
}
