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
    func walletModel() -> WalletModel
    func userWalletModel() -> UserWalletModel
    func exchangeManager(source: Currency, destination: Currency?) -> ExchangeManager
    func swappingDestinationService() -> SwappingDestinationServicing
    func currencyMapper() -> CurrencyMapping
    func tokenIconURLBuilder() -> TokenIconURLBuilding
    func userCurrenciesProvider() -> UserCurrenciesProviding
    func transactionSender() -> TransactionSendable
}
