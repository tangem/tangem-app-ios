//
//  AlephiumTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Testing
import TangemFoundation
@testable import BlockchainSdk

struct AlephiumTransactionTests {
    private let blockchain = Blockchain.alephium(testnet: false)
    private let txBuilder: AlephiumTransactionBuilder

    init() {
        let builder = AlephiumTransactionBuilder(
            isTestnet: false,
            walletPublicKey: Keys.Secp256k1.publicKey,
            decimalValue: blockchain.decimalValue
        )

        let utxo: [AlephiumUTXO] = [
            .init(
                hint: -578344929,
                key: "230eee251390aa683af312574ee647b01f6712e6cd78a2623a37da7706b347b7",
                value: Decimal(stringValue: "2000000000000000000")!,
                lockTime: 1738860822566,
                additionalData: ""
            ),
        ]

        builder.update(utxo: utxo)
        txBuilder = builder
    }

    /// Validate by https://wallet.mainnet.alephium.org/docs/#/Transactions/postTransactionsBuild
    @Test
    func correctCoinTransaction() throws {
        let transaction = transactionData()
        let hashForSign = try txBuilder.buildForSign(transaction: transaction)
        let hashForSend = try txBuilder.buildForSend(transaction: transaction)

        #expect(hashForSign.hex() == "3a939f591a551830c19ca88ffc63a51d5f2328aee994d5e6013406aea2831b65")
        #expect(hashForSend.hex() == "00000080004e20c1174876e80001dd87281f230eee251390aa683af312574ee647b01f6712e6cd78a2623a37da7706b347b700039bbd8c96ada3d42648fbe52fb40f3dae106e7552efe42a3f51583300ad5e74ab02c40de0b6b3a7640000009e36f9f01acfb951753061c56a24bc4ca2cf5de7a9ad3066fb983ea1fc3f88c800000000000000000000c40dd99bb65dd7000000727e8c40bfd803e3e0036835f584d7397729ce4e47db11e1dc72eb7ea32eeb5500000000000000000000")
    }

    private func transactionData() -> Transaction {
        let fee = Fee(
            .init(with: blockchain, type: .coin, value: Decimal(stringValue: "0")!),
            parameters: AlephiumFeeParameters(gasPrice: Decimal(stringValue: "100000000000")!, gasAmount: 20000)
        )

        let transaction = Transaction(
            amount: .init(with: blockchain, type: .coin, value: Decimal(stringValue: "1")!),
            fee: fee,
            sourceAddress: "18hwQ2uAS1EQshPbAAGK7bchM4BZBMuxyNoUsWkn2tmtp",
            destinationAddress: "1Bec3BRmSUqSx6eVChSXt3UGCvnJyKVvHbaefXwJGdW9u",
            changeAddress: "18hwQ2uAS1EQshPbAAGK7bchM4BZBMuxyNoUsWkn2tmtp"
        )

        return transaction
    }
}
