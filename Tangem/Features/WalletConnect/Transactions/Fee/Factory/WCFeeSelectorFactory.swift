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

struct SimpleAnalytics: FeeSelectorContentViewModelAnalytics {
    func logFeeStepOpened() {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
    }

    func logSendFeeSelected(_ feeOption: FeeOption) {
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
            feeTokenItem: walletModel.feeTokenItem,
            dismissButtonType: .back,
            savingType: .doneButton
        )
    }
}
