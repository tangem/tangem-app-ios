//
//  ExpressInteractorTokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol ExpressInteractorTokenFeeProvider {
    func tokenFeeManager(state: ExpressInteractor.State) -> TokenFeeManager?
    func selectedFeeProvider(state: ExpressInteractor.State) -> TokenFeeProvider?
    func feeTokenItems(state: ExpressInteractor.State) -> [TokenItem]
    func fees(state: ExpressInteractor.State) -> [TokenFee]
}
