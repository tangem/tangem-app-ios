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
    case termsAndFees
    case support
    case closeAccount

    var title: String {
        switch self {
        case .termsAndFees: Localization.moneyAccountOnboardingSecondaryButton
        case .support: Localization.tangempayPaySupport
        case .closeAccount: Localization.moneyAccountCloseAccount
        }
    }

    var subtitle: String? {
        switch self {
        case .termsAndFees, .support, .closeAccount: nil
        }
    }

    var image: ImageType {
        switch self {
        case .termsAndFees: DesignSystem.Icons.Document.regular20
        case .support: DesignSystem.Icons.Mail.regular20
        case .closeAccount: DesignSystem.Icons.Cross.regular20
        }
    }

    var style: Style {
        switch self {
        case .termsAndFees, .support: .normal
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
