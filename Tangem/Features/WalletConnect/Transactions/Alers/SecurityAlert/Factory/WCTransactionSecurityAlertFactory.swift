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
    ) -> WCTransactionAlertState? {
        let state: WCTransactionAlertState

        switch input.validationStatus {
        case .malicious, .warning, .error:
            state = .init(
                title: input.validationStatus.securityAlertTitle,
                subtitle: input.validationDescription,
                icon: .init(
                    asset: Assets.Glyphs.knightShield,
                    color: input.validationStatus == .malicious ? Colors.Icon.warning : Colors.Icon.attention
                ),
                primaryButton: .init(title: Localization.commonBack, style: .primary, isLoading: false),
                secondaryButton: .init(title: Localization.wcSendAnyway, style: .secondary, isLoading: false),
                tangemIcon: nil,
                needsHoldToConfirm: false
            )
        case .benign:
            return nil
        }

        return state
    }
}

private extension BlockaidChainScanResult.ValidationStatus {
    var securityAlertTitle: String {
        switch self {
        case .benign: ""
        case .error: Localization.wcUnknownTxNotificationTitle
        case .malicious, .warning: Localization.securityAlertTitle
        }
    }
}
