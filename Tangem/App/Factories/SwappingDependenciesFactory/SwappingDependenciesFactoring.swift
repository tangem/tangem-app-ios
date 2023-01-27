//
//  SwappingDependenciesFactoring.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExchange

protocol SwappingDependenciesFactoring {
    // [REDACTED_TODO_COMMENT]
    var walletModel: WalletModel { get }
    var userWalletModel: UserWalletModel { get }
    var swappingDestinationService: SwappingDestinationServicing { get }
    var currencyMapper: CurrencyMapping { get }
    var tokenIconURLBuilder: TokenIconURLBuilding { get }
    var userCurrenciesProvider: UserCurrenciesProviding { get }
    var transactionSender: TransactionSendable { get }

    func exchangeManager(source: Currency, destination: Currency?) -> ExchangeManager
}
