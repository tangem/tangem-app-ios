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
        let exchangeViewModelFactory = ExchangeViewModelFactory()
        let walletModelAdapter = WalletModelAdapter(walletManager: options.walletManager)
        exchangeViewModel = exchangeViewModelFactory.createExchangeViewModel(exchangeManager: walletModelAdapter,
                                                                             amountType: options.amount,
                                                                             signer: options.signer,
                                                                             blockchainNetwork: options.blockchainNetwork,
                                                                             exchangeRouter: .oneInch)
    }
}

extension ExchangeCoordinator {
    func openTokenList() { } // [REDACTED_TODO_COMMENT]

    func openApproveView() { } // [REDACTED_TODO_COMMENT]

    func openSuccessView() { } // [REDACTED_TODO_COMMENT]
}

extension ExchangeCoordinator {
    struct Options {
        let signer: TangemSigner
        let walletManager: WalletManager
        let blockchainNetwork: BlockchainNetwork
        let amount: Amount.AmountType
    }
}
