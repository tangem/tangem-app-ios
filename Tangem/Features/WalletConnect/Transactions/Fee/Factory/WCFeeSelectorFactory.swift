//
//  WCFeeSelectorFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct SimpleAnalytics: FeeSelectorAnalytics {
    func logCustomFeeClicked() {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
    }

    func logFeeSelected(tokenFee: TokenFee) {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
    }

    func logFeeSummaryOpened() {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
    }

    func logFeeTokensOpened(availableTokenFees: [TokenFee]) {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
    }

    func logFeeStepOpened() {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
    }

    func logFeeSelected(_ feeOption: FeeOption) {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
    }

    func didSelectFeeOption(_ feeOption: FeeOption) {
        if feeOption == .custom {
            Analytics.log(.sendCustomFeeClicked)
        }
    }
}

final class WCFeeSelectorFactory {
    func createFeeSelector(
        customFeeService: WCCustomEvmFeeService,
        walletModel: any WalletModel,
        feeInteractor: WCFeeInteractor
    ) -> WCFeeSelectorContentViewModel {
        WCFeeSelectorContentViewModel(
            input: feeInteractor,
            output: feeInteractor,
            analytics: SimpleAnalytics(),
            customFieldsBuilder: customFeeService,
            customAvailabilityProvider: customFeeService,
            feeTokenItem: walletModel.feeTokenItem,
            dismissButtonType: .back,
            savingType: .doneButton
        )
    }
}
