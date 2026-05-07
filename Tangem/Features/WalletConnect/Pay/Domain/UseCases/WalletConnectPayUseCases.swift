//
//  WalletConnectPayUseCases.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectPayDetectLinkUseCase {
    private let parser: WalletConnectPayLinkParser

    init(parser: WalletConnectPayLinkParser = WalletConnectPayLinkParser()) {
        self.parser = parser
    }

    func callAsFunction(_ value: String) -> WalletConnectPayLink? {
        parser.parse(value)
    }
}

struct WalletConnectPayLoadOptionsUseCase {
    private let payService: any WalletConnectPayService

    init(payService: some WalletConnectPayService) {
        self.payService = payService
    }

    func callAsFunction(
        link: WalletConnectPayLink,
        userWalletModel: any UserWalletModel,
        account: any CryptoAccountModel
    ) async throws -> WalletConnectPayOptionsResponse {
        let accounts = WalletConnectPaySupportedNetworks.evmBlockchains.flatMap { blockchain -> [WalletConnectAccount] in
            guard let chainId = blockchain.chainId else {
                return []
            }

            return userWalletModel.wcAccountsWalletModelProvider
                .getModels(with: blockchain.networkId, accountId: account.id.walletConnectIdentifierString)
                .map {
                    WalletConnectAccount(
                        namespace: WalletConnectSupportedNamespace.eip155.rawValue,
                        reference: String(chainId),
                        address: $0.walletConnectAddress
                    )
                }
        }

        return try await payService.getPaymentOptions(link: link, accounts: accounts)
    }
}

struct WalletConnectPayLoadActionsUseCase {
    private let payService: any WalletConnectPayService

    init(payService: some WalletConnectPayService) {
        self.payService = payService
    }

    func callAsFunction(paymentId: String, optionId: String) async throws -> [WalletConnectPayAction] {
        try await payService.getRequiredActions(paymentId: paymentId, optionId: optionId)
    }
}

struct WalletConnectPayConfirmUseCase {
    private let payService: any WalletConnectPayService

    init(payService: some WalletConnectPayService) {
        self.payService = payService
    }

    func callAsFunction(paymentId: String, optionId: String, signatures: [String]) async throws -> WalletConnectPayResult {
        try await payService.confirmPayment(paymentId: paymentId, optionId: optionId, signatures: signatures)
    }
}

struct WalletConnectPaySignActionsUseCase {
    private let actionDispatcher: any WalletConnectPayActionDispatching

    init(actionDispatcher: some WalletConnectPayActionDispatching) {
        self.actionDispatcher = actionDispatcher
    }

    func callAsFunction(_ actions: [WalletConnectPayAction]) async throws -> [String] {
        try await actionDispatcher.dispatch(actions)
    }
}

struct WalletConnectPayInteractor {
    let loadOptions: WalletConnectPayLoadOptionsUseCase
    let loadActions: WalletConnectPayLoadActionsUseCase
    let signActions: WalletConnectPaySignActionsUseCase
    let confirmPayment: WalletConnectPayConfirmUseCase
}
