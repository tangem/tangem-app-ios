//
//  StellarTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import stellarsdk
import Combine
import TangemSdk
import TangemFoundation
@testable import BlockchainSdk

final class StellarTransactionTests {
    private let sizeTester = TransactionSizeTesterUtility()
    private let walletPubkey = Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")
    private lazy var addressService = AddressServiceFactory(blockchain: .stellar(curve: .ed25519, testnet: false)).makeAddressService()
    private var bag = Set<AnyCancellable>()

    /// https://stellar.expert/explorer/public/tx/af9f57cdcd5710bef4f719b7679291ef3bbec58523d6b0ed77b3f8ff86edc337
    @Test(arguments: [Blockchain.stellar(curve: .ed25519, testnet: false), .stellar(curve: .ed25519_slip0010, testnet: false)])
    func testOpenTrustlineTransaction(blockchain: Blockchain) throws {
        // given
        let feeValue = Decimal(stringValue: "0.0001")!
        let fee = Fee(.init(with: blockchain, value: feeValue))
        let addressPubKey = Data(hex: "1560DFC78D683E626B986191855CAA94A33B93D95F68E1D699647AFBF61D684B")
        let address = try addressService.makeAddress(from: addressPubKey)

        let txBuilder = StellarTransactionBuilder(walletPublicKey: addressPubKey, isTestnet: false)
        txBuilder.sequence = 247738386557698163
        txBuilder.specificTxTime = 1753718404.5987458

        let token = Token(
            name: "Blend",
            symbol: "BLND",
            contractAddress: "BLND-GDJEHTBE6ZHUXSWFI642DCGLUOECLHPF3KSXHPXTSTJ7E3JF6MQ5EZYY-1",
            decimalCount: 7
        )

        let transaction = Transaction(
            amount: .zeroToken(token: token),
            fee: fee,
            sourceAddress: address.value,
            destinationAddress: address.value,
            changeAddress: "",
            contractAddress: token.contractAddress
        )

        let signature = Data(
            hex: "d712ee2e8e03e6c641426bcb1efbf7412b48b11685dc2c23a0bd264969de6f066b2488767b383feca19a869fd0f863820fb27c4ad1021c11acb350ad54bc9408"
        )

        let expectedHash = Data(hex: "af9f57cdcd5710bef4f719b7679291ef3bbec58523d6b0ed77b3f8ff86edc337")
        let expectedSignedTx = "AAAAAgAAAAAVYN/HjWg+YmuYYZGFXKqUozuT2V9o4daZZHr79h1oSwAAAGQDcCTAAAAAdAAAAAEAAAAAaIed7gAAAABoh58aAAAAAAAAAAEAAAABAAAAABVg38eNaD5ia5hhkYVcqpSjO5PZX2jh1plkevv2HWhLAAAABgAAAAFCTE5EAAAAANJDzCT2T0vKxUe5oYjLo4glneXapXO+85TT8m0l8yHSf/////////8AAAAAAAAAAfYdaEsAAABA1xLuLo4D5sZBQmvLHvv3QStIsRaF3CwjoL0mSWnebwZrJIh2ezg/7KGahp/Q+GOCD7J8StECHBGss1CtVLyUCA=="

        // when
        let signedTx = try txBuilder.buildChangeTrustOperationForSign(transaction: transaction, limit: .max)
        let (hash, txData) = signedTx

        // then
        #expect(hash == expectedHash, "Hash mismatch")
        sizeTester.testTxSize(hash)
        guard let signedTx = txBuilder.buildForSend(signature: signature, transaction: txData) else {
            #expect(Bool(false), "Failed to build transaction for send")
            return
        }
        #expect(signedTx == expectedSignedTx, "Signed transaction mismatch")
    }

    @Test(arguments: [Blockchain.stellar(curve: .ed25519, testnet: false), .stellar(curve: .ed25519_slip0010, testnet: false)])
    func correctCoinTransaction(blockchain: Blockchain) throws {
        let signature = Data(hex: "EA1908DD1B2B0937758E5EFFF18DB583E41DD47199F575C2D83B354E29BF439C850DC728B9D0B166F6F7ACD160041EE3332DAD04DD08904CB0D2292C1A9FB802")

        let sendValue = Decimal(stringValue: "0.1")!
        let feeValue = Decimal(stringValue: "0.00001")!
        let destinationAddress = "GBPMXXLHHPCOO4YOWGS4BWSVMLELZ355DVQ6JCGZX3H4HO3LH2SUETUW"

        let walletAddress = try! addressService.makeAddress(from: walletPubkey)
        let txBuilder = makeTxBuilder()

        let amountToSend = Amount(with: blockchain, type: .coin, value: sendValue)
        let feeAmount = Amount(with: blockchain, type: .coin, value: feeValue)
        let fee = Fee(feeAmount)
        let tx = Transaction(
            amount: amountToSend,
            fee: fee,
            sourceAddress: walletAddress.value,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress.value
        )

        let expectedHashToSign = Data(hex: "499fd7cd87e57c291c9e66afaf652a1e74f560cce45b5c9388bd801effdb468f")
        let expectedSignedTx = "AAAAAgAAAACf5bssx9g8HaEIRa/Yo0sUH9j9clALlbFUfhK5u4qsPQAAAGQB8CgTAAAABwAAAAEAAAAAYECf6gAAAABgQKEWAAAAAQAAAAAAAAABAAAAAQAAAACf5bssx9g8HaEIRa/Yo0sUH9j9clALlbFUfhK5u4qsPQAAAAEAAAAAXsvdZzvE53MOsaXA2lViyLzvvR1h5IjZvs/Du2s+pUIAAAAAAAAAAAAPQkAAAAAAAAAAAbuKrD0AAABA6hkI3RsrCTd1jl7/8Y21g+Qd1HGZ9XXC2Ds1Tim/Q5yFDccoudCxZvb3rNFgBB7jMy2tBN0IkEyw0iksGp+4Ag=="

        let targetAccountResponse = StellarTargetAccountResponse(accountCreated: true, trustlineCreated: true)
        let signedTx = try txBuilder.buildForSign(targetAccountResponse: targetAccountResponse, transaction: tx)
        let (hash, txData) = signedTx
        #expect(hash == expectedHashToSign)
        sizeTester.testTxSize(hash)
        guard let signedTx = txBuilder.buildForSend(signature: signature, transaction: txData) else {
            #expect(Bool(false), Comment(rawValue: "Failed to build tx for send"))
            return
        }
        #expect(signedTx == expectedSignedTx)
    }

    @Test(arguments: [EllipticCurve.ed25519, .ed25519_slip0010])
    func correctTokenTransacton(curve: EllipticCurve) throws {
        // given
        let contractAddress = "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
        let token = Token(
            name: "USDC Coin",
            symbol: "USDC",
            contractAddress: contractAddress,
            decimalCount: 18
        )
        let amount = Amount(with: token, value: Decimal(stringValue: "0.1")!)

        let walletAddress = try addressService.makeAddress(from: walletPubkey)

        let txBuilder = makeTxBuilder()

        let transaction = Transaction(
            amount: amount,
            fee: .init(.init(with: .stellar(curve: curve, testnet: false), value: Decimal(stringValue: "0.001")!)),
            sourceAddress: walletAddress.value,
            destinationAddress: "GBPMXXLHHPCOO4YOWGS4BWSVMLELZ355DVQ6JCGZX3H4HO3LH2SUETUW",
            changeAddress: walletAddress.value,
            contractAddress: "USDC-\(contractAddress)",
            params: StellarTransactionParams(memo: try StellarMemo(text: "123456"))
        )
        let targetAccountResponse = StellarTargetAccountResponse(accountCreated: true, trustlineCreated: true)

        // when
        // then

        let signedTx = try txBuilder.buildForSign(targetAccountResponse: targetAccountResponse, transaction: transaction)
        let (hash, txData) = signedTx
        #expect(hash.hex(.uppercase) == "D6EF2200869C35741B61C890481F81C7DCCF3AEC3756C074D35EDE7C789BED31")
        let dummySignature = Data(repeating: 0, count: 64)
        let messageForSend = txBuilder.buildForSend(signature: dummySignature, transaction: txData)
        #expect(
            messageForSend ==
                "AAAAAgAAAACf5bssx9g8HaEIRa/Yo0sUH9j9clALlbFUfhK5u4qsPQAAAGQB8CgTAAAABwAAAAEAAAAAYECf6gAAAABgQKEWAAAAAQAAAAYxMjM0NTYAAAAAAAEAAAABAAAAAJ/luyzH2DwdoQhFr9ijSxQf2P1yUAuVsVR+Erm7iqw9AAAAAQAAAABey91nO8Tncw6xpcDaVWLIvO+9HWHkiNm+z8O7az6lQgAAAAFVU0RDAAAAADuZETgO/piLoKiQDrHP5E82b32+lGvtB3JA9/Yk3xXFAAAAAAAPQkAAAAAAAAAAAbuKrD0AAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
        )
    }

    private func makeTxBuilder() -> StellarTransactionBuilder {
        let txBuilder = StellarTransactionBuilder(walletPublicKey: walletPubkey, isTestnet: false)
        txBuilder.sequence = 139655650517975046
        txBuilder.specificTxTime = 1614848128.2697558
        return txBuilder
    }
}
