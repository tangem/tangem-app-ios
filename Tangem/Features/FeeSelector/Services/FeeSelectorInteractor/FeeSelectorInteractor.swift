//
//  FeeSelectorInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol FeeSelectorInteractor: FeeSelectorTokensDataProvider, FeeSelectorFeesDataProvider, FeeSelectorCustomFeeDataProviding {
    var state: FeeSelectorInteractorState { get }

    func userDidSelect(feeTokenItem: TokenItem)
    func userDidSelect(feeOption: FeeOption)

    func completeSelection()
    func userDidDismissFeeSelection()
}

enum FeeSelectorInteractorState {
    case single
    case multiple
}
