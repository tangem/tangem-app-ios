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

struct SimpleCustomFeeFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder {
    let customFeeService: CustomFeeService?

    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel] {
        guard let customFeeService else {
            return []
        }

        return customFeeService.selectorCustomFeeRowViewModels()
    }
}

struct SimpleAnalytics: FeeSelectorContentViewModelAnalytics {
    func logSendFeeSelected(_ feeOption: FeeOption) {
        // [REDACTED_TODO_COMMENT]
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
    ) -> FeeSelectorContentViewModel {
        FeeSelectorContentViewModel(
            input: feeInteractor,
            output: feeInteractor,
            analytics: SimpleAnalytics(),
            customFieldsBuilder: SimpleCustomFeeFieldsBuilder(customFeeService: customFeeService),
            feeTokenItem: walletModel.feeTokenItem,
            dismissButtonType: .back
        )
    }
}
