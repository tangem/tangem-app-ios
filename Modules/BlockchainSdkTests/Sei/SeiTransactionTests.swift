//
//  SeiTransactionTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import Testing
import TangemSdk
@testable import BlockchainSdk

struct SeiTransactionTests {
    private let cosmosChain: CosmosChain
    private let blockchain: BlockchainSdk.Blockchain
    private let privateKey: PrivateKey
    private let publicKey: PublicKey
    private let txBuilder: CosmosTransactionBuilder

    init() {
        cosmosChain = CosmosChain.sei(testnet: true)
        blockchain = cosmosChain.blockchain
        privateKey = PrivateKey(data: Data(hexString: "80e81ea269e66a0a05b11236df7919fb7fbeedba87452d667489d7403a02f005"))!
        publicKey = privateKey.getPublicKeySecp256k1(compressed: true)
        txBuilder = try! CosmosTransactionBuilder(
            publicKey: privateKey.getPublicKeySecp256k1(compressed: true).data,
            cosmosChain: cosmosChain
        )
    }

    @Test
    func correctCoinTransaction() throws {
        let transaction = try makeSeiTransaction(txBuilder: txBuilder)
        let dataForSign = try txBuilder.buildForSign(transaction: transaction)

        #expect(dataForSign.hex() == "9a2af4a0e1519d73a5f44ee99e9e9b11077f1779b4486bb4bf7949d65516e3ad")

        let signature = try #require(privateKey.sign(digest: dataForSign, curve: cosmosChain.coin.curve))
        #expect(signature.hex() == "07e4d05edf18cb3ab8f41f03337f5177587a65ac1b4a555e129f276752afcf14230d53ed9c970edec3ec843414a7695566eb31e7fae89065c67386d7c32afe6a00")

        let transactionData = try txBuilder.buildForSend(transaction: transaction, signature: signature)

        let transactionString = try #require(String(data: transactionData, encoding: .utf8))
        let expectedOutput =
            """
            {
                "mode":"BROADCAST_MODE_SYNC",
                "tx_bytes":"CoYBCoMBChwvY29zbW9zLmJhbmsudjFiZXRhMS5Nc2dTZW5kEmMKKnNlaTFoc2s2anJ5eXFqZmhwNWRoYzU1dGM5anRja3lneDBlcDZrdW1mdBIqc2VpMXM0cXB3YWpuMzZrazZkcDBjNHl1Mjd2M3c4N3hoYzVwaDZ5ZWtxGgkKBHVzZWkSATESZQpQCkYKHy9jb3Ntb3MuY3J5cHRvLnNlY3AyNTZrMS5QdWJLZXkSIwohAlcobsPzfTNVe7uqAAsndErJAjqplnyudaGB0f+R+p3FEgQKAggBGAgSEQoLCgR1c2VpEgMyMDAQwJoMGkAH5NBe3xjLOrj0HwMzf1F3WHplrBtKVV4SnydnUq/PFCMNU+2clw7ew+yENBSnaVVm6zHn+uiQZcZzhtfDKv5q"
            }
            """

        expectJSONEqual(transactionString, expectedOutput)
    }

    @Test
    func transactionSize() throws {
        let sizeTester = TransactionSizeTesterUtility()
        let transaction = try makeSeiTransaction(txBuilder: txBuilder)
        let dataForSign = try txBuilder.buildForSign(transaction: transaction)

        sizeTester.testTxSize(dataForSign)
    }
}

private extension SeiTransactionTests {
    func makeSeiTransaction(txBuilder: CosmosTransactionBuilder) throws -> Transaction {
        let address = try AddressServiceFactory(blockchain: blockchain).makeAddressService().makeAddress(from: publicKey.data)
        let wallet = Wallet(blockchain: blockchain, addresses: [.default: address])

        txBuilder.setAccountNumber(1037)
        txBuilder.setSequenceNumber(8)

        let transaction = Transaction(
            amount: Amount(with: cosmosChain.blockchain, value: 0.000001),
            fee: Fee(
                Amount(with: cosmosChain.blockchain, value: 0.000200),
                parameters: CosmosFeeParameters(gas: 200_000)
            ),
            sourceAddress: wallet.address,
            destinationAddress: "sei1s4qpwajn36kk6dp0c4yu27v3w87xhc5ph6yekq",
            changeAddress: wallet.address
        )

        return transaction
    }
}
