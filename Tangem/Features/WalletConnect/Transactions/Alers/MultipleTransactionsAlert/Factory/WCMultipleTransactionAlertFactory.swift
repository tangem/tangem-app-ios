//
//  WCMultipleTransactionAlertFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemAssets
import TangemUI

enum WCMultipleTransactionsAlertFactory {
    static func makeMultipleTransactionAlertState(
        signingActionButtonType: SigningActionButtonViewType
    ) -> WCTransactionAlertState {
        let state: WCTransactionAlertState = .init(
            title: Localization.walletConnectMultipleTransactions,
            subtitle: Localization.walletConnectMultipleTransactionsDescription,
            icon: .init(
                asset: Assets.blueCircleWarning,
                color: Colors.Icon.accent
            ),
            primaryButton: .init(title: Localization.commonSend, style: .primary, isLoading: false),
            secondaryButton: .init(title: Localization.commonBack, style: .secondary, isLoading: false),
            signingActionButtonType: signingActionButtonType
        )

        return state
    }
}
