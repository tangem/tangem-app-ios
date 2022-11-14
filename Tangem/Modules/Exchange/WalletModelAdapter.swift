//
//  WalletModelAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class WalletModelAdapter: ExchangeManager {
    var walletAddress: String {
        walletManager.wallet.address
    }

    private let walletManager: WalletManager

    init(walletManager: WalletManager) {
        self.walletManager = walletManager
    }

    func send(_ tx: Transaction, signer: TangemSigner) async throws {
        try await walletManager.send(tx, signer: signer).async()
    }

    func getFee(currency: Currency, destination: String) async throws -> [Currency] {
        if currency.isToken {
            let amount = amount = Amount(with: .init(name: "",
                                        symbol: "",
                                        contractAddress: currency.contractAddress,
                                        decimalCount: currency.decimalCount ?? 0),
                            value: currency.amount)
        } else {
            amount = Amount(with: currency.blockchainNetwork.blockchain, value: 0)
        }
        return try await walletManager
            .getFee(amount: amount, destination: destination)
            .map({ amounts in
                return [
                    Currency(amount: amounts[0].value, blockchainNetwork: currency.blockchainNetwork),
                    Currency(amount: amounts[1].value, blockchainNetwork: currency.blockchainNetwork),
                    Currency(amount: amounts[2].value, blockchainNetwork: currency.blockchainNetwork),
                ]
            })
            .eraseToAnyPublisher()
            .async()
    }

    func createTransaction(for currency: Currency,
                           fee: Decimal,
                           destinationAddress: String,
                           sourceAddress: String?,
                           changeAddress: String?) throws -> Transaction {
        let txAmount = Amount(with: .init(name: currency.name ?? "",
                                          symbol: currency.symbol ?? "",
                                          contractAddress: currency.contractAddress,
                                          decimalCount: currency.decimalCount ?? 0),
                              value: currency.amount)

        let txFee = Amount(with: currency.blockchainNetwork.blockchain, value: fee)

        return try walletManager.createTransaction(amount: txAmount,
                                                   fee: txFee,
                                                   destinationAddress: destinationAddress,
                                                   sourceAddress: sourceAddress,
                                                   changeAddress: changeAddress)
    }
}
