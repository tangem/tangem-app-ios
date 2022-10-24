//
//  ExchangeCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class ExchangeCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>
    
    @Published var exchangeViewModel: ExchangeViewModel? = nil
    
    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }
    
    func start(with options: ExchangeCoordinator.Options) {
        exchangeViewModel = ExchangeViewModel(amountType: options.amountType, walletModel: options.walletModel, cardViewModel: options.cardViewModel, blockchainNetwork: options.blockchainNetwork)
    }
    
}

extension ExchangeCoordinator {
    struct Options {
        let cardViewModel: CardViewModel
        let walletModel: WalletModel
        let amountType: Amount.AmountType
        let blockchainNetwork: BlockchainNetwork
    }
}
