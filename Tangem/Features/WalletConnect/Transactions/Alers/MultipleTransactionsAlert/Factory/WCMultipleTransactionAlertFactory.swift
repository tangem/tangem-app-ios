//
//  WCMultipleTransactionAlertFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemAssets

enum WCMultipleTransactionsAlertFactory {
    static func makeMultipleTransactionAlertState(
        tangemIconProvider: TangemIconProvider,
        confirmTransactionPolicy: ConfirmTransactionPolicy
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
            tangemIcon: tangemIconProvider.getMainButtonIcon(),
            needsHoldToConfirm: confirmTransactionPolicy.needsHoldToConfirm
        )

        return state
    }
}
