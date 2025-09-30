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
        walletModelProvider: WalletConnectWalletModelProvider,
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
        walletModelProvider: WalletConnectWalletModelProvider,
        connectedDApp: WalletConnectConnectedDApp
    ) throws -> WalletConnectMessageHandler {
        switch action {
            // MARK: - ETH

        case .personalSign:
            return try WalletConnectV2PersonalSignHandler(
                request: params,
                blockchainId: blockchainNetworkID,
                signer: CommonWalletConnectSigner(signer: signer),
                walletModelProvider: walletModelProvider
            )

        case .addChain:
            return try WalletConnectAddEthereumChainMessageHandler(
                requestParams: params,
                connectedDApp: connectedDApp,
                walletModelProvider: walletModelProvider
            )

        case .switchChain:
            return try WalletConnectSwitchEthereumChainMessageHandler(requestParams: params, connectedDApp: connectedDApp)

        case .signTypedData, .signTypedDataV4:
            return try WalletConnectV2SignTypedDataHandler(
                requestParams: params,
                blockchainId: blockchainNetworkID,
                signer: CommonWalletConnectSigner(signer: signer),
                walletModelProvider: walletModelProvider
            )

        case .signTransaction:
            return try WalletConnectV2SignTransactionHandler(
                requestParams: params,
                blockchainId: blockchainNetworkID,
                transactionBuilder: ethTransactionBuilder,
                signer: signer,
                walletModelProvider: walletModelProvider
            )

        case .sendTransaction:
            return try WalletConnectV2SendTransactionHandler(
                requestParams: params,
                blockchainId: blockchainNetworkID,
                transactionBuilder: ethTransactionBuilder,
                signer: signer,
                walletModelProvider: walletModelProvider
            )

        // MARK: - Solana

        case .solanaSignMessage:
            return try WalletConnectSolanaSignMessageHandler(
                request: params,
                signer: SolanaWalletConnectSigner(signer: signer),
                blockchainId: blockchainNetworkID,
                walletModelProvider: walletModelProvider
            )

        case .solanaSignTransaction:
            return try WalletConnectSolanaSignTransactionHandler(
                request: params,
                blockchainId: blockchainNetworkID,
                signer: signer,
                walletNetworkServiceFactory: walletNetworkServiceFactoryProvider.factory,
                walletModelProvider: walletModelProvider,
                analyticsProvider: makeAnalyticsProvider(with: connectedDApp.dAppData)
            )

        case .solanaSignAllTransactions:
            return try WCSolanaSignAllTransactionsHandler(
                request: params,
                blockchainId: blockchainNetworkID,
                signer: SolanaWalletConnectSigner(signer: signer),
                walletModelProvider: walletModelProvider
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

    private func makeAnalyticsProvider(with dAppData: WalletConnectDAppData?) -> WalletConnectServiceAnalyticsProvider {
        CommonWalletConnectServiceAnalyticsProvider(dAppData: dAppData)
    }
}
