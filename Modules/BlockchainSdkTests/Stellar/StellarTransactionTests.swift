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
    private lazy var addressService = StellarAddressService()
    private var bag = Set<AnyCancellable>()

    init() {
        bag = []
    }

    @Test(arguments: [Blockchain.stellar(curve: .ed25519, testnet: false), .stellar(curve: .ed25519_slip0010, testnet: false)])
    func correctCoinTransaction(blockchain: Blockchain) async {
        let signature = Data(hex: "EA1908DD1B2B0937758E5EFFF18DB583E41DD47199F575C2D83B354E29BF439C850DC728B9D0B166F6F7ACD160041EE3332DAD04DD08904CB0D2292C1A9FB802")

        let sendValue = Decimal(0.1)
        let feeValue = Decimal(0.00001)
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

        await confirmation { confirmation in
            txBuilder.buildForSign(targetAccountResponse: targetAccountResponse, transaction: tx)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        #expect(Bool(false), Comment(rawValue: "Failed to build tx. Reason: \(error.localizedDescription)"))
                    }
                }, receiveValue: { hash, txData in
                    #expect(hash == expectedHashToSign)

                    self.sizeTester.testTxSize(hash)
                    guard let signedTx = txBuilder.buildForSend(signature: signature, transaction: txData) else {
                        #expect(Bool(false), Comment(rawValue: "Failed to build tx for send"))
                        return
                    }

                    #expect(signedTx == expectedSignedTx)

                    confirmation()
                    return
                })
                .store(in: &bag)
        }
    }

    @Test(arguments: [EllipticCurve.ed25519, .ed25519_slip0010])
    func correctTokenTransacton(curve: EllipticCurve) async throws {
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
            contractAddress: contractAddress,
            params: StellarTransactionParams(memo: try StellarMemo(text: "123456"))
        )
        let targetAccountResponse = StellarTargetAccountResponse(accountCreated: true, trustlineCreated: true)

        // when
        // then
        await confirmation { confirmation in
            txBuilder.buildForSign(targetAccountResponse: targetAccountResponse, transaction: transaction)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        #expect(Bool(false), Comment(rawValue: "Failed to build tx. Reason: \(error.localizedDescription)"))
                    }
                }, receiveValue: { hash, txData in
                    #expect(hash.hex(.uppercase) == "D6EF2200869C35741B61C890481F81C7DCCF3AEC3756C074D35EDE7C789BED31")

                    let dummySignature = Data(repeating: 0, count: 64)
                    let messageForSend = txBuilder.buildForSend(signature: dummySignature, transaction: txData)

                    #expect(
                        messageForSend ==
                            "AAAAAgAAAACf5bssx9g8HaEIRa/Yo0sUH9j9clALlbFUfhK5u4qsPQAAAGQB8CgTAAAABwAAAAEAAAAAYECf6gAAAABgQKEWAAAAAQAAAAYxMjM0NTYAAAAAAAEAAAABAAAAAJ/luyzH2DwdoQhFr9ijSxQf2P1yUAuVsVR+Erm7iqw9AAAAAQAAAABey91nO8Tncw6xpcDaVWLIvO+9HWHkiNm+z8O7az6lQgAAAAFVU0RDAAAAADuZETgO/piLoKiQDrHP5E82b32+lGvtB3JA9/Yk3xXFAAAAAAAPQkAAAAAAAAAAAbuKrD0AAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
                    )

                    confirmation()
                    return
                })
                .store(in: &bag)
        }
    }

    private func makeTxBuilder() -> StellarTransactionBuilder {
        let txBuilder = StellarTransactionBuilder(walletPublicKey: walletPubkey, isTestnet: false)
        txBuilder.sequence = 139655650517975046
        txBuilder.specificTxTime = 1614848128.2697558
        return txBuilder
    }
}
