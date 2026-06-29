//
//  TransactionHistoryServiceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TransactionHistoryServiceProvider {
    func makeTransactionHistoryService(tokenItem: TokenItem, walletManager: any WalletManager) -> TransactionHistoryService? {
        if tokenItem.blockchain.isDynamicAddressesSupported {
            return WalletTransactionHistoryService(
                tokenItem: tokenItem,
                walletProvider: walletManager,
                transactionHistoryProviderFactory: TransactionHistoryFactoryProvider().factory
            )
        }

        var addresses = walletManager.wallet.addresses.map { $0.value }

        if tokenItem.blockchain.isEvm {
            let converter = EthereumAddressConverterFactory().makeConverter(for: tokenItem.blockchainNetwork.blockchain)
            let convertedAddresses = addresses.map { (try? converter.convertToETHAddress($0)) ?? $0 }
            addresses = Array(Set(convertedAddresses))
        }

        if let address = addresses.singleElement {
            let factory = TransactionHistoryFactoryProvider().factory

            guard let provider = factory.makeProvider(for: tokenItem.blockchain, isToken: tokenItem.isToken) else {
                return nil
            }

            return CommonTransactionHistoryService(
                tokenItem: tokenItem,
                address: address,
                transactionHistoryProvider: provider
            )
        }

        let multiAddressProviders: [String: BlockchainSdk.TransactionHistoryProvider] = addresses.reduce(into: [:]) { result, address in
            let factory = TransactionHistoryFactoryProvider().factory
            if let provider = factory.makeProvider(for: tokenItem.blockchain, isToken: tokenItem.isToken) {
                result[address] = provider
            }
        }

        guard !multiAddressProviders.isEmpty else {
            return nil
        }

        return MultipleAddressTransactionHistoryService(
            tokenItem: tokenItem,
            addresses: addresses,
            transactionHistoryProviders: multiAddressProviders.compactMapValues { $0 }
        )
    }
}
