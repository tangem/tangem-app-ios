//
//  WalletConnectV2HandlersFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk
import struct Commons.AnyCodable

protocol WalletConnectHandlersCreator: AnyObject {
    func createHandler(
        for action: WalletConnectMethod,
        with params: AnyCodable,
        blockchainNetworkID: String,
        signer: TangemSigner,
        hardwareLimitationsUtil: HardwareLimitationsUtil,
        walletModelProvider: WalletConnectWalletModelProvider,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        connectedDApp: WalletConnectConnectedDApp
    ) throws -> WalletConnectMessageHandler
}

final class WalletConnectHandlersFactory: WalletConnectHandlersCreator {
    private let ethTransactionBuilder: WCEthTransactionBuilder
    private let walletNetworkServiceFactoryProvider: WalletNetworkServiceFactoryProvider

    init(
        ethTransactionBuilder: WCEthTransactionBuilder,
        walletNetworkServiceFactoryProvider: WalletNetworkServiceFactoryProvider
    ) {
        self.ethTransactionBuilder = ethTransactionBuilder
        self.walletNetworkServiceFactoryProvider = walletNetworkServiceFactoryProvider
    }

    func createHandler(
        for action: WalletConnectMethod,
        with params: AnyCodable,
        blockchainNetworkID: String,
        signer: TangemSigner,
        hardwareLimitationsUtil: HardwareLimitationsUtil,
        walletModelProvider: WalletConnectWalletModelProvider,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        connectedDApp: WalletConnectConnectedDApp
    ) throws -> WalletConnectMessageHandler {
        let walletScope = resolveWalletScope(for: connectedDApp)

        switch action {
            // MARK: - ETH

        case .personalSign:
            return try makeHandler(
                for: walletScope,
                accountBuilder: { accountId in
                    try WalletConnectV2PersonalSignHandler(
                        request: params,
                        blockchainId: blockchainNetworkID,
                        signer: CommonWalletConnectSigner(signer: signer),
                        wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                        accountId: accountId
                    )
                },
                walletBuilder: {
                    try WalletConnectV2PersonalSignHandler(
                        request: params,
                        blockchainId: blockchainNetworkID,
                        signer: CommonWalletConnectSigner(signer: signer),
                        walletModelProvider: walletModelProvider
                    )
                }
            )

        case .addChain:
            return try WalletConnectAddEthereumChainMessageHandler(
                requestParams: params,
                connectedDApp: connectedDApp,
                walletModelProvider: walletModelProvider,
                wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                accountId: connectedDApp.accountId ?? ""
            )

        case .switchChain:
            return try WalletConnectSwitchEthereumChainMessageHandler(requestParams: params, connectedDApp: connectedDApp)

        case .signTypedData, .signTypedDataV4:
            return try makeHandler(
                for: walletScope,
                accountBuilder: { accountId in
                    try WalletConnectV2SignTypedDataHandler(
                        requestParams: params,
                        blockchainId: blockchainNetworkID,
                        signer: CommonWalletConnectSigner(signer: signer),
                        wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                        accountId: accountId
                    )
                },
                walletBuilder: {
                    try WalletConnectV2SignTypedDataHandler(
                        requestParams: params,
                        blockchainId: blockchainNetworkID,
                        signer: CommonWalletConnectSigner(signer: signer),
                        walletModelProvider: walletModelProvider
                    )
                }
            )

        case .signTransaction:
            return try makeHandler(
                for: walletScope,
                accountBuilder: { accountId in
                    try WalletConnectV2SignTransactionHandler(
                        requestParams: params,
                        blockchainId: blockchainNetworkID,
                        transactionBuilder: ethTransactionBuilder,
                        signer: signer,
                        wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                        accountId: accountId
                    )
                },
                walletBuilder: {
                    try WalletConnectV2SignTransactionHandler(
                        requestParams: params,
                        blockchainId: blockchainNetworkID,
                        transactionBuilder: ethTransactionBuilder,
                        signer: signer,
                        walletModelProvider: walletModelProvider
                    )
                }
            )

        case .sendTransaction:
            return try makeHandler(
                for: walletScope,
                accountBuilder: { accountId in
                    try WalletConnectV2SendTransactionHandler(
                        requestParams: params,
                        blockchainId: blockchainNetworkID,
                        transactionBuilder: ethTransactionBuilder,
                        signer: signer,
                        wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                        accountId: accountId
                    )
                },
                walletBuilder: {
                    try WalletConnectV2SendTransactionHandler(
                        requestParams: params,
                        blockchainId: blockchainNetworkID,
                        transactionBuilder: ethTransactionBuilder,
                        signer: signer,
                        walletModelProvider: walletModelProvider
                    )
                }
            )

        // MARK: - Solana

        case .solanaSignMessage:
            return try makeHandler(
                for: walletScope,
                accountBuilder: { accountId in
                    try WalletConnectSolanaSignMessageHandler(
                        request: params,
                        signer: SolanaWalletConnectSigner(signer: signer),
                        blockchainId: blockchainNetworkID,
                        wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                        accountId: accountId
                    )
                },
                walletBuilder: {
                    try WalletConnectSolanaSignMessageHandler(
                        request: params,
                        signer: SolanaWalletConnectSigner(signer: signer),
                        blockchainId: blockchainNetworkID,
                        walletModelProvider: walletModelProvider
                    )
                }
            )

        case .solanaSignTransaction:
            return try makeHandler(
                for: walletScope,
                accountBuilder: { accountId in
                    try WalletConnectSolanaSignTransactionHandler(
                        request: params,
                        blockchainId: blockchainNetworkID,
                        signer: signer,
                        hardwareLimitationsUtil: hardwareLimitationsUtil,
                        walletNetworkServiceFactory: walletNetworkServiceFactoryProvider.factory,
                        wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                        accountId: accountId,
                        analyticsProvider: makeAnalyticsProvider(with: connectedDApp.dAppData)
                    )
                },
                walletBuilder: {
                    try WalletConnectSolanaSignTransactionHandler(
                        request: params,
                        blockchainId: blockchainNetworkID,
                        signer: signer,
                        hardwareLimitationsUtil: hardwareLimitationsUtil,
                        walletNetworkServiceFactory: walletNetworkServiceFactoryProvider.factory,
                        walletModelProvider: walletModelProvider,
                        analyticsProvider: makeAnalyticsProvider(with: connectedDApp.dAppData)
                    )
                }
            )

        case .solanaSignAllTransactions:
            return try makeHandler(
                for: walletScope,
                accountBuilder: { accountId in
                    try WCSolanaSignAllTransactionsHandler(
                        request: params,
                        blockchainId: blockchainNetworkID,
                        signer: SolanaWalletConnectSigner(signer: signer),
                        wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                        accountId: accountId
                    )
                },
                walletBuilder: {
                    try WCSolanaSignAllTransactionsHandler(
                        request: params,
                        blockchainId: blockchainNetworkID,
                        signer: SolanaWalletConnectSigner(signer: signer),
                        walletModelProvider: walletModelProvider
                    )
                }
            )

        // MARK: - BNB

        case .bnbSign, .bnbTxConfirmation:
            // [REDACTED_TODO_COMMENT]
            // Initially this methods was found occasionally and supported without any request
            // Need to find documentation and find place where it can be tested on 2.0
            // This page https://www.bnbchain.org/en/staking has WalletConnect in status 'Coming Soon'
            throw WalletConnectTransactionRequestProcessingError.unsupportedMethod(action.rawValue)
        }
    }

    // MARK: - Private Implementation

    private func resolveWalletScope(for connectedDApp: WalletConnectConnectedDApp) -> WalletScope {
        switch connectedDApp {
        case .v1:
            if FeatureProvider.isAvailable(.accounts) {
                return .account(accountId: connectedDApp.accountId ?? "")
            } else {
                return .wallet
            }
        case .v2(let walletConnectConnectedDAppV2):
            return .account(accountId: walletConnectConnectedDAppV2.accountId)
        }
    }

    private func makeHandler(
        for scope: WalletScope,
        accountBuilder: (String) throws -> WalletConnectMessageHandler,
        walletBuilder: () throws -> WalletConnectMessageHandler
    ) throws -> WalletConnectMessageHandler {
        switch scope {
        case .account(let accountId):
            return try accountBuilder(accountId)
        case .wallet:
            return try walletBuilder()
        }
    }

    private func makeAnalyticsProvider(with dAppData: WalletConnectDAppData?) -> WalletConnectServiceAnalyticsProvider {
        CommonWalletConnectServiceAnalyticsProvider(dAppData: dAppData)
    }
}

private extension WalletConnectHandlersFactory {
    enum WalletScope {
        case account(accountId: String)
        case wallet
    }
}
