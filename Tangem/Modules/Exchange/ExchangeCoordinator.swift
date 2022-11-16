//
//  ExchangeCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExchange

class ExchangeCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    @Published var exchangeViewModel: ExchangeViewModel? = nil

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: ExchangeCoordinator.Options) {
        let manager = TangemExchangeFactory.createExchangeManager(
            source: options.sourceCurrency,
            destination: nil,
            blockchainProvider: options.blockchainProvider
        )
        exchangeViewModel = ExchangeViewModel(router: self, exchangeManager: manager)
    }
}

// MARK: - Options

extension ExchangeCoordinator {
    struct Options {
        let signer: TangemSigner
        let sourceCurrency: Currency
        let blockchainProvider: BlockchainNetworkProvider
    }
}

// MARK: - ExchangeRoutable

extension ExchangeCoordinator: ExchangeRoutable {
    func openTokenList() { } // [REDACTED_TODO_COMMENT]

    func openApproveView() { } // [REDACTED_TODO_COMMENT]

    func openSuccessView() { } // [REDACTED_TODO_COMMENT]
}
