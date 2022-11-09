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
        let factory = ExchangeTokensFactory()
        let exchangeFacadeFactory = ExchangeFacadeFactory()

        let exchangeCurrency: ExchangeCurrency
        switch options.amount {
        case .coin:
            do {
                exchangeCurrency = try factory.createCoin(for: options.walletModel.blockchainNetwork)
            } catch {
                exchangeCurrency = ExchangeCurrency(type: .coin(blockchainNetwork: options.walletModel.blockchainNetwork))
            }
        case .token:
            let contractAddress = options.amount.token?.contractAddress ?? ""
            exchangeCurrency = ExchangeCurrency(type: .token(blockchainNetwork: options.walletModel.blockchainNetwork, contractAddress: contractAddress))
        default:
            fatalError("")
        }

        exchangeViewModel = ExchangeViewModel(currency: exchangeCurrency,
                                              exchangeFacade: exchangeFacadeFactory.createFacade(for: .oneInch,
                                                                                                 exchangeManager: options.walletModel,
                                                                                                 signer: options.signer))
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
        let walletModel: WalletModel
        let amount: Amount.AmountType
    }
}
