//
//  TangemPayMoneyAccountMenuItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

enum TangemPayMoneyAccountMenuItem: Hashable {
    case currentPlan(planName: String)
    case termsAndFees
    case support
    case closeAccount

    var title: String {
        switch self {
        case .currentPlan: Localization.tangempayCurrentPlanTitle
        case .termsAndFees: Localization.moneyAccountOnboardingSecondaryButton
        case .support: Localization.tangempayPaySupport
        case .closeAccount: Localization.moneyAccountCloseAccount
        }
    }

    var subtitle: String? {
        switch self {
        case .currentPlan(let planName): planName
        case .termsAndFees, .support, .closeAccount: nil
        }
    }

    var image: ImageType {
        switch self {
        case .currentPlan: DesignSystem.Icons.Info.regular20
        case .termsAndFees: DesignSystem.Icons.Document.regular20
        case .support: DesignSystem.Icons.Mail.regular20
        case .closeAccount: DesignSystem.Icons.Cross.regular20
        }
    }

    var style: Style {
        switch self {
        case .currentPlan, .termsAndFees, .support: .normal
        case .closeAccount: .destructive
        }
    }
}

// MARK: - Style

extension TangemPayMoneyAccountMenuItem {
    enum Style {
        case normal
        case destructive
    }
}
