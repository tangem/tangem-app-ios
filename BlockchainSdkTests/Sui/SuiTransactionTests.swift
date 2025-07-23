//
//  SuiTransactionTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
import class WalletCore.PrivateKey
@testable import BlockchainSdk

struct SuiTransactionTests {
    @Test
    func testCoinBuildForInspect() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: Self.makeCoinsWithSuiAndUsdc())

        let coinAmount = Amount(with: Self.suiBlockchain, type: .coin, value: 0.3)
        let receivedTransactionString = try sut.buildForInspect(amount: coinAmount, destination: walletAddress, referenceGasPrice: 1000)

        let expectedTransactionString = "AAACAAgAo+ERAAAAAAAgVOgNdteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rICAgABAQAAAQED"
            + "AAAAAAEBAFToDXbXkMJ39aRPPOkvU9JvWJSJK/OV3uY3WYiHa+ayAQ3cofff68w1uKEjhmDazVBiERYUwRjM1s0bo"
            + "JWLpc/zNyzlEwAAAAAgAEjhf33FW2O7fAi2fBNdv3GP4r5VBU6W6S/8bpQJOAxU6A1215DCd/WkTzzpL1PSb1iUiS"
            + "vzld7mN1mIh2vmsugDAAAAAAAAAAivLwAAAAAA"

        #expect(receivedTransactionString == expectedTransactionString)
    }

    @Test
    func testTokenBuildForInspect() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: Self.makeCoinsWithSuiAndUsdc())

        let tokenAmount = Amount(with: Self.usdcToken, value: 2)
        let receivedTransactionString = try sut.buildForInspect(amount: tokenAmount, destination: walletAddress, referenceGasPrice: 1000)

        let expectedTransactionString = "AAADAQBB4LZd5jlHL3Es176QPchaFfgiFDiRGmG3VN7UCOPoJl7RzxQAAAAAIMhSn7Jnyoi/"
            + "+ON+BzXO30MXGQen2v3hork6Wkq1BWK6AAiAhB4AAAAAAAAgVOgNdteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5r"
            + "ICAgEAAAEBAQABAQMAAAAAAQIAVOgNdteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rIBDdyh99/rzDW4oSOGYNr"
            + "NUGIRFhTBGMzWzRuglYulz/M3LOUTAAAAACAASOF/fcVbY7t8CLZ8E12/cY/ivlUFTpbpL/xulAk4DFToDXbXkMJ3"
            + "9aRPPOkvU9JvWJSJK/OV3uY3WYiHa+ay6AMAAAAAAAAAq5BBAAAAAAA="

        #expect(receivedTransactionString == expectedTransactionString)
    }

    @Test
    func testBuildForInspectFailsForInvalidAmount() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: Self.makeCoinsWithSuiAndUsdc())

        do {
            let unsupportedAmount = Amount(type: .feeResource(.mana), currencySymbol: "ANY_CURRENCY", value: 12, decimals: 9)
            _ = try sut.buildForInspect(amount: unsupportedAmount, destination: walletAddress, referenceGasPrice: 1000)
        } catch BlockchainSdkError.failedToBuildTx {
            // expected error thrown. Task failed successfully :)
        } catch {
            let expectedError = BlockchainSdkError.failedToBuildTx
            #expect(Bool(false), "Expected to fail with: \(expectedError), received: \(error)")
        }
    }

    @Test
    func testCoinBuildTransaction() throws {
        let privateKeyRaw = Data(hex: "7e6682f7bf479ef0f627823cffd4e1a940a7af33e5fb39d9e0f631d2ecc5daff")
        let privateKey = try #require(PrivateKey(data: privateKeyRaw))

        let publicKey = Wallet.PublicKey(seedKey: privateKey.getPublicKeyEd25519().data, derivationType: nil)
        let walletAddress = try Self.makeWalletAddress(publicKey: publicKey)
        let coinTransaction = Self.makeCoinTransaction(walletAddress: walletAddress)

        let sut = Self.makeSUT(walletAddress: walletAddress, publicKey: publicKey)
        sut.update(coins: Self.makeCoinsWithSuiAndUsdc())

        let receivedDataForSign = try sut.buildForSign(transaction: coinTransaction)

        let expectedDataForSign = try #require(Data(base64Encoded: "q4PTuVfYzD1Qy5xch0vOEbgQfhvpFK+vrYKQK8z5vNs="))
        #expect(receivedDataForSign == expectedDataForSign)
        TransactionSizeTesterUtility().testTxSize(receivedDataForSign)

        let signatureHex = "f40d654e0fdd36d6270c25ca0691d941bc41a2f6d83ac8e8512b12fedd67b2"
            + "dcb998f2378098af090532185e043f87b2d5719b7edd60cdfecb23d1b538d8ce0d"
        let signatureData = Data(hex: signatureHex)

        let sendOutput = try sut.buildForSend(transaction: coinTransaction, signature: signatureData)

        let expectedTransactionBytes = "AAACAAjoAwAAAAAAAAAgVOgNdteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rICA"
            + "gABAQAAAQEDAAAAAAEBAFToDXbXkMJ39aRPPOkvU9JvWJSJK/OV3uY3WYiHa+ayAQ3cofff68w1uKEjhmDazVBiERY"
            + "UwRjM1s0boJWLpc/zNyzlEwAAAAAgAEjhf33FW2O7fAi2fBNdv3GP4r5VBU6W6S/8bpQJOAxU6A1215DCd/WkTzzpL"
            + "1PSb1iUiSvzld7mN1mIh2vmsu4CAAAAAAAAwMYtAAAAAAAA"

        let expectedSignature = "APQNZU4P3TbWJwwlygaR2UG8QaL22DrI6FErEv7dZ7LcuZjyN4CYrwkFMhheBD+HstVxm37d"
            + "YM3+yyPRtTjYzg2F69FEH+T5VPvl3GB3vwCOEZpeJpKXxvcIPQAdKsh2/g=="

        #expect(sendOutput.txBytes == expectedTransactionBytes)
        #expect(sendOutput.signature == expectedSignature)
    }

    @Test
    func testTokenBuildTransaction() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        let tokenTransaction = Self.makeTokenTransaction(walletAddress: walletAddress)

        sut.update(coins: Self.makeCoinsWithSuiAndUsdc())
        let receivedDataForSign = try sut.buildForSign(transaction: tokenTransaction)

        let expectedDataForSign = try #require(Data(base64Encoded: "U+/jDrOT5RZ5c90d2v07aKvdWH14B/mAKkkporeggsE="))
        #expect(receivedDataForSign == expectedDataForSign)
        TransactionSizeTesterUtility().testTxSize(receivedDataForSign)

        let signatureHex = "f40d654e0fdd36d6270c25ca0691d941bc41a2f6d83ac8e8512b12fedd67b2"
            + "dcb998f2378098af090532185e043f87b2d5719b7edd60cdfecb23d1b538d8ce0d"
        let signatureData = Data(hex: signatureHex)

        let sendOutput = try sut.buildForSend(transaction: tokenTransaction, signature: signatureData)

        let expectedTransactionBytes = "AAADAQBB4LZd5jlHL3Es176QPchaFfgiFDiRGmG3VN7UCOPoJl7RzxQAAAAAIMhSn"
            + "7Jnyoi/+ON+BzXO30MXGQen2v3hork6Wkq1BWK6AAiAhB4AAAAAAAAgVOgNdteQwnf1pE886S9T0m9YlIkr85Xe5jd"
            + "ZiIdr5rICAgEAAAEBAQABAQMAAAAAAQIAVOgNdteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rIBDdyh99/rzDW4o"
            + "SOGYNrNUGIRFhTBGMzWzRuglYulz/M3LOUTAAAAACAASOF/fcVbY7t8CLZ8E12/cY/ivlUFTpbpL/xulAk4DFToDXb"
            + "XkMJ39aRPPOkvU9JvWJSJK/OV3uY3WYiHa+ay6AMAAAAAAADgsEYAAAAAAAA="

        let expectedSignature = "APQNZU4P3TbWJwwlygaR2UG8QaL22DrI6FErEv7dZ7LcuZjyN4CYrwkFMhheBD+HstVxm37d"
            + "YM3+yyPRtTjYzg2F69FEH+T5VPvl3GB3vwCOEZpeJpKXxvcIPQAdKsh2/g=="

        #expect(sendOutput.txBytes == expectedTransactionBytes)
        #expect(sendOutput.signature == expectedSignature)
    }

    @Test
    func testBuildForSignFailsForInvalidTransaction() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: Self.makeCoinsWithSuiAndUsdc())

        do {
            let invalidTransaction = Transaction(
                amount: Amount(type: .feeResource(.mana), currencySymbol: "ANY_CURRENCY", value: 12, decimals: 9),
                fee: Fee(.init(with: Self.suiBlockchain, value: 0), parameters: nil),
                sourceAddress: walletAddress,
                destinationAddress: walletAddress,
                changeAddress: ""
            )
            _ = try sut.buildForSign(transaction: invalidTransaction)
        } catch BlockchainSdkError.failedToBuildTx {
            // expected error thrown. Task failed successfully :)
        } catch {
            let expectedError = BlockchainSdkError.failedToBuildTx
            #expect(Bool(false), "Expected to fail with: \(expectedError), received: \(error)")
        }
    }

    @Test
    func testCheckCoinGasBalanceIsEnoughForTokenTransaction() throws {
        let sut = try Self.makeSUT()

        let smallCoinsWithTotalBalanceLessThanOne = [
            Self.makeSuiCoin(balance: 0.2),
            Self.makeSuiCoin(balance: 0.5),
            Self.makeSuiCoin(balance: 0.1),
        ]

        sut.update(coins: smallCoinsWithTotalBalanceLessThanOne)
        #expect(sut.checkIfCoinGasBalanceIsNotEnoughForTokenTransaction())

        let smallCoinsWithTotalBalanceMoreThanOne = [
            Self.makeSuiCoin(balance: 0.2),
            Self.makeSuiCoin(balance: 0.5),
            Self.makeSuiCoin(balance: 0.9),
        ]

        sut.update(coins: smallCoinsWithTotalBalanceMoreThanOne)
        #expect(sut.checkIfCoinGasBalanceIsNotEnoughForTokenTransaction())

        let coinsWithEnoughGasBalance = [
            Self.makeSuiCoin(balance: 1),
            Self.makeSuiCoin(balance: 0.05),
        ]

        sut.update(coins: coinsWithEnoughGasBalance)
        #expect(!sut.checkIfCoinGasBalanceIsNotEnoughForTokenTransaction())
    }
}

// MARK: - Sample data and factory methods

extension SuiTransactionTests {
    static let suiBlockchain = Blockchain.sui(curve: .ed25519_slip0010, testnet: false)
    static let suiCoinDecimalValue = Decimal(1_000_000_000)
    static let usdcTokenDecimalValue = Decimal(100_000)
    static let usdcToken = Token(
        name: "USDC",
        symbol: "USDC",
        contractAddress: "0xa1ec7fc00a6f40db9693ad1415d0c193ad3906494428cf252621037bd7117e29::usdc::USDC",
        decimalCount: 6,
        id: "usd-coin"
    )

    private static func makeSUT(walletAddress: String, publicKey: Wallet.PublicKey) -> SuiTransactionBuilder {
        SuiTransactionBuilder(walletAddress: walletAddress, publicKey: publicKey, decimalValue: suiCoinDecimalValue)
    }

    private static func makeWalletAddressAndSUT() throws -> (String, SuiTransactionBuilder) {
        let seedKey = Data(hex: "85ebd1441fe4f954fbe5dc6077bf008e119a5e269297c6f7083d001d2ac876fe")
        let publicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: nil)
        let walletAddress = try Self.makeWalletAddress(publicKey: publicKey)

        return (walletAddress, Self.makeSUT(walletAddress: walletAddress, publicKey: publicKey))
    }

    private static func makeSUT() throws -> SuiTransactionBuilder {
        let (_, sut) = try Self.makeWalletAddressAndSUT()
        return sut
    }

    private static func makeCoinTransaction(walletAddress: String) -> Transaction {
        let amount = Amount(with: Self.suiBlockchain, value: Decimal(1000) / Self.suiCoinDecimalValue)
        let fee = Fee(
            Amount(with: Self.suiBlockchain, value: 0),
            parameters: SuiFeeParameters(gasPrice: 750, gasBudget: 3000000)
        )

        return Transaction(amount: amount, fee: fee, sourceAddress: walletAddress, destinationAddress: walletAddress, changeAddress: "")
    }

    private static func makeTokenTransaction(walletAddress: String) -> Transaction {
        let amount = Amount(with: Self.usdcToken, value: 2)
        let fee = Fee(
            Amount(with: Self.suiBlockchain, value: 0.0046328),
            parameters: SuiFeeParameters(gasPrice: 1000, gasBudget: 4632800)
        )

        return Transaction(amount: amount, fee: fee, sourceAddress: walletAddress, destinationAddress: walletAddress, changeAddress: "")
    }

    private static func makeCoinsWithSuiAndUsdc() -> [SuiCoinObject] {
        [
            makeSuiCoin(balance: 1.1),
            makeUSDCCoin(balance: 5),
        ]
    }

    private static func makeSuiCoin(balance: Decimal) -> SuiCoinObject {
        SuiCoinObject(
            coinType: .init(contract: "0x2", lowerID: "sui", upperID: "SUI"),
            coinObjectId: "0x0ddca1f7dfebcc35b8a1238660dacd5062111614c118ccd6cd1ba0958ba5cff3",
            version: 333786167,
            digest: "127TTe3fyhURjzUxAhByCVxb5TkQbkBiLmk8xnpiuy2b",
            balance: balance * suiCoinDecimalValue
        )
    }

    private static func makeUSDCCoin(balance: Decimal) -> SuiCoinObject {
        SuiCoinObject(
            coinType: .init(contract: "0xa1ec7fc00a6f40db9693ad1415d0c193ad3906494428cf252621037bd7117e29", lowerID: "usdc", upperID: "USDC"),
            coinObjectId: "0x41e0b65de639472f712cd7be903dc85a15f8221438911a61b754ded408e3e826",
            version: 349163870,
            digest: "EUycXN2FyHc9zqJBQMfyxSndHxE32BZfvRhTC5wWJqUd",
            balance: balance * usdcTokenDecimalValue
        )
    }

    private static func makeWalletAddress(publicKey: Wallet.PublicKey) throws -> String {
        try AddressServiceFactory(blockchain: .sui(curve: .ed25519_slip0010, testnet: false))
            .makeAddressService()
            .makeAddress(for: publicKey, with: .default).value
    }
}
