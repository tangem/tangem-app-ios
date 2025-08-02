//
//  WCTransactionSecurityAlertFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemAssets

enum WCTransactionSecurityAlertFactory {
    static func makeSecurityAlertState(
        input: WCTransactionSecurityAlertInput
    ) -> WCTransactionSecurityAlertState? {
        let state: WCTransactionSecurityAlertState

        switch input.validationStatus {
        case .malicious, .warning:
            state = .init(
                title: Localization.securityAlertTitle,
                subtitle: input.validationDescription ?? input.validationStatus.rawValue,
                icon: .init(
                    asset: Assets.Glyphs.knightShield,
                    color: input.validationStatus == .malicious ? Colors.Icon.warning : Colors.Icon.attention
                ),
                primaryButton: .init(title: Localization.commonBack, style: .primary, isLoading: false),
                secondaryButton: .init(title: Localization.wcSendAnyway, style: .secondary, isLoading: false)
            )
        case .benign:
            return nil
        }

        return state
    }
}
