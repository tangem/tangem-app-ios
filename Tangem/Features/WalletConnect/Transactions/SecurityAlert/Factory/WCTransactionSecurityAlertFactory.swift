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
    static func makeSecurityAlertViewModel(
        input: WCTransactionSecurityAlertInput,
    ) -> WCTransactionSecurityAlertViewModel? {
        let state: WCTransactionSecurityAlertState

        switch input.validationStatus {
        case .malicious, .warning:
            state = .init(
                title: Localization.securityAlertTitle,
                subtitle: input.validationStatus.description,
                icon: .init(asset: Assets.Glyphs.knightShield, color: Colors.Icon.warning),
                primaryButton: .init(title: Localization.commonCancel, style: .primary),
                secondaryButton: .init(title: "Send anyway", style: .secondary)
            )
        case .benign:
            return nil
        }

        return WCTransactionSecurityAlertViewModel(state: state, input: input)
    }
}
