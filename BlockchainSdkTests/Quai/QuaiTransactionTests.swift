//
//  QuaiTransactionTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing
import WalletCore
import BigInt

struct QuaiTransactionTests {
    private let protoUtils = QuaiProtobufUtils()

    private let rawPublicKey = Data(hex: "04fd5e187de4e07d17f71d14e6574a7e54265b0cdf86cb4b3ea824e925821bd6816d5a84440829f952966fdd96fb42113cc36c2f2cf87aadb92e7a73ca86d690bd")

    private let blockchain = Blockchain.quai(testnet: false)
    private let chainId = 9
    private let walletAddress = "0x004842973c76D783037E41eb3917DAc7777dA099"
    private let destinationAddress = "0x0027405CF43C57277b20D866f0f0bDca0D59071A"
    private let feeParameters = EthereumLegacyFeeParameters(gasLimit: BigUInt(28000), gasPrice: BigUInt(7465326404574))

    @Test
    func transferCoinTransaction() throws {
        // given
        let nonce = 23

        let walletPublicKey = Wallet.PublicKey(seedKey: rawPublicKey, derivationType: nil)
        let sourceAddress = PlainAddress(value: walletAddress, publicKey: walletPublicKey, type: .default)

        let signature = Data(hex: "d90a028a29161381e85b36ecd61c0196e45598df4a582c358402306717cbcf94675a492faf527c47e72ca1a28a45801d40ea5c61bcab0656dfc54382c5dc72df")

        let sendAmount = Amount(with: blockchain, type: .coin, value: Decimal(stringValue: "0.01")!)

        // feeAmount doesn't matter. The EthereumFeeParameters used to build the transaction
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        let transaction = Transaction(
            amount: sendAmount,
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress,
            params: EthereumTransactionParams(nonce: nonce)
        )

        // when
        let transactionBuilder = QuaiTransactionBuilder(chainId: chainId, sourceAddress: sourceAddress)
        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        let signatureInfo = SignatureInfo(signature: signature, publicKey: rawPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)

        // then
        let expectedHashToSign = Data(hex: "114366848b001f0c58ec06f7dfd6418f93d20052f02e496a1d370ecc38453edb")
        let expectedSignedTransaction = Data(hex: "080012140027405cf43c57277b20d866f0f0bdca0d59071a181722072386f26fc1000028e0da0132003a0109420606ca2820e3de4a005201005a20d90a028a29161381e85b36ecd61c0196e45598df4a582c358402306717cbcf946220675a492faf527c47e72ca1a28a45801d40ea5c61bcab0656dfc54382c5dc72df")

        #expect(hashToSign == expectedHashToSign)
        #expect(signedTransaction == expectedSignedTransaction)
    }

    @Test
    func transferTokenTransaction() throws {
        // given
        let nonce = 23

        let walletPublicKey = Wallet.PublicKey(seedKey: rawPublicKey, derivationType: nil)
        let sourceAddress = PlainAddress(value: walletAddress, publicKey: walletPublicKey, type: .default)

        let signature = Data(hex: "01b7afc5d39533178dde5239e9a76f4a322ce4258d10cb11bf2bf572b8cb8788767b45597533ebc3811bc1be4c5a15ce3f71ee2df4c73b4381185930e363feb7")

        let sendAmount = Amount(with: blockchain, type: .token(value: .WQiToken), value: Decimal(stringValue: "0.01")!)

        // feeAmount doesn't matter. The EthereumFeeParameters used to build the transaction
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        let transaction = Transaction(
            amount: sendAmount,
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress,
            params: EthereumTransactionParams(nonce: nonce)
        )

        // when
        let transactionBuilder = QuaiTransactionBuilder(chainId: chainId, sourceAddress: sourceAddress)
        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        let signatureInfo = SignatureInfo(signature: signature, publicKey: rawPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)

        // then
        let expectedHashToSign = Data(hex: "5656945a8df7b7fd0c9548ede5be52fe3124ed053d29a240b18a83b4a7988456")
        let expectedSignedTransaction = Data(hex: "08001214002b2596ecf05c93a31ff916e8b456df6c77c7501817220028e0da013244a9059cbb0000000000000000000000000027405cf43c57277b20d866f0f0bdca0d59071a000000000000000000000000000000000000000000000000002386f26fc100003a0109420606ca2820e3de4a005201005a2001b7afc5d39533178dde5239e9a76f4a322ce4258d10cb11bf2bf572b8cb87886220767b45597533ebc3811bc1be4c5a15ce3f71ee2df4c73b4381185930e363feb7")

        #expect(hashToSign == expectedHashToSign)
        #expect(signedTransaction == expectedSignedTransaction)
    }
}

extension Token {
    static let WQiToken: Self = .init(
        name: "Wrapped Quai Token (WQi)",
        symbol: "WQi",
        contractAddress: "0x002b2596EcF05C93a31ff916E8b456DF6C77c750",
        decimalCount: 18
    )
}
