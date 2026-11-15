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

    func userDidSelect(feeProviderID: TokenFeeProviderID)
    func userDidSelect(feeOption: FeeOption)

    func completeSelection()
}

enum FeeSelectorInteractorState {
    case single
    case multiple
}
