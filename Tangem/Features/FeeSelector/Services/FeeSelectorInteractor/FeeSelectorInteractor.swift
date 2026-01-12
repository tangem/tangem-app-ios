//
//  FeeSelectorInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol FeeSelectorInteractorInput: AnyObject {
    var selectedFee: TokenFee { get }
    var selectedFeePublisher: AnyPublisher<TokenFee, Never> { get }
}

protocol FeeSelectorInteractor: FeeSelectorTokensDataProvider, FeeSelectorFeesDataProvider, FeeSelectorCustomFeeDataProviding {
    func userDidSelectTokenItem(_ tokenItem: TokenItem)
    func userDidSelectFee(_ fee: TokenFee)
}
