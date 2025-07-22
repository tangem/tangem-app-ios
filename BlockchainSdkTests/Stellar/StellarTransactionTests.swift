//
//  StellarTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import stellarsdk
import Combine
import TangemSdk
@testable import BlockchainSdk
import Testing

final class StellarTransactionTests {
    private let sizeTester = TransactionSizeTesterUtility()
    private let walletPubkey = Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")
    private lazy var addressService = AddressServiceFactory(blockchain: .stellar(curve: .ed25519, testnet: false)).makeAddressService()
    private var bag = Set<AnyCancellable>()

    @Test(arguments: [Blockchain.stellar(curve: .ed25519, testnet: false), .stellar(curve: .ed25519_slip0010, testnet: false)])
    func testOpenTrustlineTransaction(blockchain: Blockchain) async throws {
        // given
        let feeValue = Decimal(string: "0.000100")!
        let fee = Fee(.init(with: blockchain, value: feeValue))
        let addressPubKey = Data(hex: "1560DFC78D683E626B986191855CAA94A33B93D95F68E1D699647AFBF61D684B")
        let address = try addressService.makeAddress(from: addressPubKey)

        let txBuilder = StellarTransactionBuilder(walletPublicKey: addressPubKey, isTestnet: false)
        txBuilder.sequence = 247738386557698095
        txBuilder.specificTxTime = 1614848128.2697558

        let token = Token(
            name: "EURC",
            symbol: "EURC",
            contractAddress: "EURC-GAQRF3UGHBT6JYQZ7YSUYCIYWAF4T2SAA5237Q5LIQYJOHHFAWDXZ7NM",
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
            hex: "05a3c43a7bb71f13434eff96d8ec483f53afb0ff434fb75e6ec749cc10b9f0bafae79c7d70919c171be5c8daf03278bc8aaa9670dabcff971c2215eeb7faaf00"
        )

        let expectedHash = Data(hex: "8965ffecb1cbbf9c9236156e802802322c8b5cb2f3c01a058521c86e3964c1e3")
        let expectedSignedTx = "AAAAAgAAAAAVYN/HjWg+YmuYYZGFXKqUozuT2V9o4daZZHr79h1oSwAAAGQDcCTAAAAAMAAAAAEAAAAAYECf6gAAAABgQKEWAAAAAAAAAAEAAAABAAAAABVg38eNaD5ia5hhkYVcqpSjO5PZX2jh1plkevv2HWhLAAAABgAAAAFFVVJDAAAAACES7oY4Z+TiGf4lTAkYsAvJ6kAHdb/Dq0QwlxzlBYd8fOZsUOKEAAAAAAAAAAAAAfYdaEsAAABABaPEOnu3HxNDTv+W2OxIP1OvsP9DT7debsdJzBC58Lr655x9cJGcFxvlyNrwMni8iqqWcNq8/5ccIhXut/qvAA=="

        // when
        let result = try await txBuilder
            .buildChangeTrustOperationForSign(transaction: transaction, limit: .max)
            .mapToResult()
            .async()

        // then
        switch result {
        case .success(let (hash, txData)):
            #expect(hash == expectedHash, "Hash mismatch")
            sizeTester.testTxSize(hash)

            guard let signedTx = txBuilder.buildForSend(signature: signature, transaction: txData) else {
                #expect(Bool(false), "Failed to build transaction for send")
                return
            }

            #expect(signedTx == expectedSignedTx, "Signed transaction mismatch")

        case .failure(let failure):
            #expect(Bool(false), "Failed to build operation: \(failure.localizedDescription)")
        }
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
            contractAddress: "USDC-\(contractAddress)",
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

private extension Publisher {
    func mapToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        map(Result.success)
            .catch { Just(.failure($0)) }
            .eraseToAnyPublisher()
    }
}
