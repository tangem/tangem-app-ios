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
    private let btcTransactionBuilder: WCBtcTransactionBuilder
    private let walletNetworkServiceFactoryProvider: WalletNetworkServiceFactoryProvider

    init(
        ethTransactionBuilder: WCEthTransactionBuilder,
        btcTransactionBuilder: WCBtcTransactionBuilder,
        walletNetworkServiceFactoryProvider: WalletNetworkServiceFactoryProvider
    ) {
        self.ethTransactionBuilder = ethTransactionBuilder
        self.btcTransactionBuilder = btcTransactionBuilder
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
        switch action {
            // MARK: - ETH

        case .personalSign:
            switch connectedDApp {
            case .v1:
                return try WalletConnectV2PersonalSignHandler(
                    request: params,
                    blockchainId: blockchainNetworkID,
                    signer: CommonWalletConnectSigner(signer: signer),
                    walletModelProvider: walletModelProvider
                )
            case .v2(let walletConnectConnectedDAppV2):
                return try WalletConnectV2PersonalSignHandler(
                    request: params,
                    blockchainId: blockchainNetworkID,
                    signer: CommonWalletConnectSigner(signer: signer),
                    wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                    accountId: walletConnectConnectedDAppV2.accountId
                )
            }

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
            switch connectedDApp {
            case .v1:
                return try WalletConnectV2SignTypedDataHandler(
                    requestParams: params,
                    blockchainId: blockchainNetworkID,
                    signer: CommonWalletConnectSigner(signer: signer),
                    walletModelProvider: walletModelProvider
                )
            case .v2(let walletConnectConnectedDAppV2):
                return try WalletConnectV2SignTypedDataHandler(
                    requestParams: params,
                    blockchainId: blockchainNetworkID,
                    signer: CommonWalletConnectSigner(signer: signer),
                    wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                    accountId: walletConnectConnectedDAppV2.accountId
                )
            }

        case .signTransaction:
            switch connectedDApp {
            case .v1:
                return try WalletConnectV2SignTransactionHandler(
                    requestParams: params,
                    blockchainId: blockchainNetworkID,
                    transactionBuilder: ethTransactionBuilder,
                    signer: signer,
                    walletModelProvider: walletModelProvider
                )
            case .v2(let walletConnectConnectedDAppV2):
                return try WalletConnectV2SignTransactionHandler(
                    requestParams: params,
                    blockchainId: blockchainNetworkID,
                    transactionBuilder: ethTransactionBuilder,
                    signer: signer,
                    wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                    accountId: walletConnectConnectedDAppV2.accountId
                )
            }

        case .sendTransaction:
            switch connectedDApp {
            case .v1:
                return try WalletConnectV2SendTransactionHandler(
                    requestParams: params,
                    blockchainId: blockchainNetworkID,
                    transactionBuilder: ethTransactionBuilder,
                    signer: signer,
                    walletModelProvider: walletModelProvider
                )
            case .v2(let walletConnectConnectedDAppV2):
                return try WalletConnectV2SendTransactionHandler(
                    requestParams: params,
                    blockchainId: blockchainNetworkID,
                    transactionBuilder: ethTransactionBuilder,
                    signer: signer,
                    wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                    accountId: walletConnectConnectedDAppV2.accountId
                )
            }

        // MARK: - Solana

        case .solanaSignMessage:
            switch connectedDApp {
            case .v1:
                return try WalletConnectSolanaSignMessageHandler(
                    request: params,
                    signer: SolanaWalletConnectSigner(signer: signer),
                    blockchainId: blockchainNetworkID,
                    walletModelProvider: walletModelProvider
                )
            case .v2(let walletConnectConnectedDAppV2):
                return try WalletConnectSolanaSignMessageHandler(
                    request: params,
                    signer: SolanaWalletConnectSigner(signer: signer),
                    blockchainId: blockchainNetworkID,
                    wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                    accountId: walletConnectConnectedDAppV2.accountId
                )
            }

        case .solanaSignTransaction:
            switch connectedDApp {
            case .v1:
                return try WalletConnectSolanaSignTransactionHandler(
                    request: params,
                    blockchainId: blockchainNetworkID,
                    signer: signer,
                    hardwareLimitationsUtil: hardwareLimitationsUtil,
                    walletNetworkServiceFactory: walletNetworkServiceFactoryProvider.factory,
                    walletModelProvider: walletModelProvider,
                    analyticsProvider: makeAnalyticsProvider(with: connectedDApp.dAppData)
                )
            case .v2(let walletConnectConnectedDAppV2):
                return try WalletConnectSolanaSignTransactionHandler(
                    request: params,
                    blockchainId: blockchainNetworkID,
                    signer: signer,
                    hardwareLimitationsUtil: hardwareLimitationsUtil,
                    walletNetworkServiceFactory: walletNetworkServiceFactoryProvider.factory,
                    wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                    accountId: walletConnectConnectedDAppV2.accountId,
                    analyticsProvider: makeAnalyticsProvider(with: connectedDApp.dAppData)
                )
            }

        case .solanaSignAllTransactions:
            switch connectedDApp {
            case .v1:
                return try WCSolanaSignAllTransactionsHandler(
                    request: params,
                    blockchainId: blockchainNetworkID,
                    signer: SolanaWalletConnectSigner(signer: signer),
                    walletModelProvider: walletModelProvider
                )
            case .v2(let walletConnectConnectedDAppV2):
                return try WCSolanaSignAllTransactionsHandler(
                    request: params,
                    blockchainId: blockchainNetworkID,
                    signer: SolanaWalletConnectSigner(signer: signer),
                    wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                    accountId: walletConnectConnectedDAppV2.accountId
                )
            }

        // MARK: - BNB

        case .bnbSign, .bnbTxConfirmation:
            // [REDACTED_TODO_COMMENT]
            // Initially this methods was found occasionally and supported without any request
            // Need to find documentation and find place where it can be tested on 2.0
            // This page https://www.bnbchain.org/en/staking has WalletConnect in status 'Coming Soon'
            throw WalletConnectTransactionRequestProcessingError.unsupportedMethod(action.rawValue)

        // MARK: - Bitcoin

        case .sendTransfer:
            return try WalletConnectSendTransferHandler(
                requestParams: params,
                blockchainId: blockchainNetworkID,
                transactionBuilder: btcTransactionBuilder,
                signer: signer,
                walletModelProvider: walletModelProvider
            )

        case .getAccountAddresses:
            switch connectedDApp {
            case .v1:
                return try WalletConnectBitcoinGetAccountAddressesHandler(
                    request: params,
                    blockchainId: blockchainNetworkID,
                    walletModelProvider: walletModelProvider
                )
            case .v2(let walletConnectConnectedDAppV2):
                return try WalletConnectBitcoinGetAccountAddressesHandler(
                    request: params,
                    blockchainId: blockchainNetworkID,
                    wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                    accountId: walletConnectConnectedDAppV2.accountId
                )
            }

        case .signPsbt:
            switch connectedDApp {
            case .v1:
                return try WalletConnectBitcoinSignPsbtHandler(
                    request: params,
                    blockchainId: blockchainNetworkID,
                    transactionBuilder: btcTransactionBuilder,
                    signer: signer,
                    walletModelProvider: walletModelProvider
                )
            case .v2(let walletConnectConnectedDAppV2):
                return try WalletConnectBitcoinSignPsbtHandler(
                    request: params,
                    blockchainId: blockchainNetworkID,
                    transactionBuilder: btcTransactionBuilder,
                    signer: signer,
                    wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                    accountId: walletConnectConnectedDAppV2.accountId
                )
            }

        case .signMessage:
            return try WalletConnectBitcoinSignMessageHandler(
                request: params,
                blockchainId: blockchainNetworkID,
                signer: BitcoinWalletConnectSigner(signer: signer),
                walletModelProvider: walletModelProvider
            )
        }
    }

    // MARK: - Private Implementation

    private func makeAnalyticsProvider(with dAppData: WalletConnectDAppData?) -> WalletConnectServiceAnalyticsProvider {
        CommonWalletConnectServiceAnalyticsProvider(dAppData: dAppData)
    }
}
