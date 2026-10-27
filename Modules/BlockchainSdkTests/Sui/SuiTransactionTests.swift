//
//  SuiTransactionTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import Testing
import class WalletCore.PrivateKey
@testable import BlockchainSdk

struct SuiTransactionTests {
    @Test
    func testCoinBuildForInspect() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: Self.makeCoinsWithSuiAndUsdc(), balances: [])

        let coinAmount = Amount(with: Self.suiBlockchain, type: .coin, value: 0.3)
        let receivedTransactionString = try sut.buildForInspect(
            amount: coinAmount,
            destination: walletAddress,
            referenceGasPrice: 1000,
            serviceInfo: Self.serviceInfo
        )

        let expectedTransactionString = "AAACAAgAo+ERAAAAAAAgVOgNdteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rICAgABAQAAAQED"
            + "AAAAAAEBAFToDXbXkMJ39aRPPOkvU9JvWJSJK/OV3uY3WYiHa+ayAQ3cofff68w1uKEjhmDazVBiERYUwRjM1s0bo"
            + "JWLpc/zNyzlEwAAAAAgAEjhf33FW2O7fAi2fBNdv3GP4r5VBU6W6S/8bpQJOAxU6A1215DCd/WkTzzpL1PSb1iUiS"
            + "vzld7mN1mIh2vmsugDAAAAAAAAAAivLwAAAAAA"

        #expect(receivedTransactionString == expectedTransactionString)
    }

    @Test
    func testTokenBuildForInspect() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: Self.makeCoinsWithSuiAndUsdc(), balances: [])

        let tokenAmount = Amount(with: Self.usdcToken, value: 2)
        let receivedTransactionString = try sut.buildForInspect(
            amount: tokenAmount,
            destination: walletAddress,
            referenceGasPrice: 1000,
            serviceInfo: Self.serviceInfo
        )

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
        sut.update(coins: Self.makeCoinsWithSuiAndUsdc(), balances: [])

        do {
            let unsupportedAmount = Amount(type: .feeResource(.mana), currencySymbol: "ANY_CURRENCY", value: 12, decimals: 9)
            _ = try sut.buildForInspect(
                amount: unsupportedAmount,
                destination: walletAddress,
                referenceGasPrice: 1000,
                serviceInfo: Self.serviceInfo
            )
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
        sut.update(coins: Self.makeCoinsWithSuiAndUsdc(), balances: [])

        let transactionBytes = try sut.buildTransaction(transaction: coinTransaction, serviceInfo: Self.serviceInfo)
        let receivedDataForSign = try sut.buildForSign(transactionBytes: transactionBytes)

        let expectedDataForSign = try #require(Data(base64Encoded: "q4PTuVfYzD1Qy5xch0vOEbgQfhvpFK+vrYKQK8z5vNs="))
        #expect(receivedDataForSign == expectedDataForSign)
        TransactionSizeTesterUtility().testTxSize(receivedDataForSign)

        let signatureHex = "f40d654e0fdd36d6270c25ca0691d941bc41a2f6d83ac8e8512b12fedd67b2"
            + "dcb998f2378098af090532185e043f87b2d5719b7edd60cdfecb23d1b538d8ce0d"
        let signatureData = Data(hex: signatureHex)

        let sendOutput = try sut.buildForSend(transactionBytes: transactionBytes, signature: signatureData)

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

        sut.update(coins: Self.makeCoinsWithSuiAndUsdc(), balances: [])
        let transactionBytes = try sut.buildTransaction(transaction: tokenTransaction, serviceInfo: Self.serviceInfo)
        let receivedDataForSign = try sut.buildForSign(transactionBytes: transactionBytes)

        let expectedDataForSign = try #require(Data(base64Encoded: "U+/jDrOT5RZ5c90d2v07aKvdWH14B/mAKkkporeggsE="))
        #expect(receivedDataForSign == expectedDataForSign)
        TransactionSizeTesterUtility().testTxSize(receivedDataForSign)

        let signatureHex = "f40d654e0fdd36d6270c25ca0691d941bc41a2f6d83ac8e8512b12fedd67b2"
            + "dcb998f2378098af090532185e043f87b2d5719b7edd60cdfecb23d1b538d8ce0d"
        let signatureData = Data(hex: signatureHex)

        let sendOutput = try sut.buildForSend(transactionBytes: transactionBytes, signature: signatureData)

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
        sut.update(coins: Self.makeCoinsWithSuiAndUsdc(), balances: [])

        do {
            let invalidTransaction = Transaction(
                amount: Amount(type: .feeResource(.mana), currencySymbol: "ANY_CURRENCY", value: 12, decimals: 9),
                fee: Fee(.init(with: Self.suiBlockchain, value: 0), parameters: nil),
                sourceAddress: walletAddress,
                destinationAddress: walletAddress,
                changeAddress: ""
            )
            _ = try sut.buildTransaction(transaction: invalidTransaction, serviceInfo: Self.serviceInfo)
        } catch BlockchainSdkError.failedToBuildTx {
            // expected error thrown. Task failed successfully :)
        } catch {
            let expectedError = BlockchainSdkError.failedToBuildTx
            #expect(Bool(false), "Expected to fail with: \(expectedError), received: \(error)")
        }
    }

    @Test
    func testCheckSuiBalanceIsEnoughForTokenTransaction() throws {
        let sut = try Self.makeSUT()

        let smallCoinsWithTotalBalanceLessThanOne = [
            Self.makeSuiCoin(balance: 0.2),
            Self.makeSuiCoin(balance: 0.5),
            Self.makeSuiCoin(balance: 0.1),
        ]

        sut.update(coins: smallCoinsWithTotalBalanceLessThanOne, balances: [])
        #expect(sut.checkIfSuiBalanceIsNotEnoughForTokenTransaction())

        let smallCoinsWithTotalBalanceMoreThanOne = [
            Self.makeSuiCoin(balance: 0.2),
            Self.makeSuiCoin(balance: 0.5),
            Self.makeSuiCoin(balance: 0.9),
        ]

        sut.update(coins: smallCoinsWithTotalBalanceMoreThanOne, balances: [])
        #expect(!sut.checkIfSuiBalanceIsNotEnoughForTokenTransaction())

        sut.update(coins: [], balances: [Self.makeSuiBalance(addressBalance: 0.5)])
        #expect(sut.checkIfSuiBalanceIsNotEnoughForTokenTransaction())

        sut.update(coins: [], balances: [Self.makeSuiBalance(addressBalance: 2)])
        #expect(!sut.checkIfSuiBalanceIsNotEnoughForTokenTransaction())
    }

    @Test
    func testCoinTransactionFromAddressBalanceOnly() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: [], balances: [Self.makeSuiBalance(addressBalance: 2)])

        let transaction = Self.makeTransaction(
            walletAddress: walletAddress,
            amount: Amount(with: Self.suiBlockchain, value: 0.5),
            fee: SuiFeeParameters(gasPrice: 750, gasBudget: 3000000)
        )
        let transactionBytes = try sut.buildTransaction(transaction: transaction, serviceInfo: Self.serviceInfo)

        let expectedTransactionBytes = "AAACAgAAZc0dAAAAAAAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDc3VpA1NVSQAAACBU6A1215DCd/WkTzzpL1PS"
            + "b1iUiSvzld7mN1mIh2vmsgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIEY29pbgxyZWRlZW1fZnVuZHMBBwAAAAAA"
            + "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACA3N1aQNTVUkAAQEAAAEBAgAAAQEAVOgNdteQwnf1pE886S9T0m9YlIkr85Xe5jdZ"
            + "iIdr5rIAVOgNdteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rLuAgAAAAAAAMDGLQAAAAAAAgEMBQAAAAAAAAENBQAAAAAAAAAA"
            + "IDWDSorBfKSPsUrI+ZwXyYdH6V3QcpSuQaRrOCJGpEmbKgAAAA=="

        #expect(transactionBytes == expectedTransactionBytes)

        let dataForSign = try sut.buildForSign(transactionBytes: transactionBytes)
        let expectedDataForSign = try #require(Data(base64Encoded: "eCP0Y1/maGPl6LEjFv9h9HPvYPp4JUKC4X0wivlyvFk="))
        #expect(dataForSign == expectedDataForSign)
        TransactionSizeTesterUtility().testTxSize(dataForSign)

        let signatureHex = "f40d654e0fdd36d6270c25ca0691d941bc41a2f6d83ac8e8512b12fedd67b2"
            + "dcb998f2378098af090532185e043f87b2d5719b7edd60cdfecb23d1b538d8ce0d"
        let sendOutput = try sut.buildForSend(transactionBytes: transactionBytes, signature: Data(hex: signatureHex))

        let expectedSignature = "APQNZU4P3TbWJwwlygaR2UG8QaL22DrI6FErEv7dZ7LcuZjyN4CYrwkFMhheBD+HstVxm37d"
            + "YM3+yyPRtTjYzg2F69FEH+T5VPvl3GB3vwCOEZpeJpKXxvcIPQAdKsh2/g=="

        #expect(sendOutput.txBytes == expectedTransactionBytes)
        #expect(sendOutput.signature == expectedSignature)
    }

    @Test
    func testCoinTransactionWithCoinGasAndAddressBalanceWithdrawal() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: [Self.makeSuiCoin(balance: 1.1)], balances: [Self.makeSuiBalance(addressBalance: 2)])

        let transaction = Self.makeTransaction(
            walletAddress: walletAddress,
            amount: Amount(with: Self.suiBlockchain, value: 1.5),
            fee: SuiFeeParameters(gasPrice: 750, gasBudget: 3000000)
        )
        let transactionBytes = try sut.buildTransaction(transaction: transaction, serviceInfo: Self.serviceInfo)

        let expectedTransactionBytes = "AAADAgDASgUYAAAAAAAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDc3VpA1NVSQAAAAgAL2hZAAAAAAAgVOgNdteQ"
            + "wnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rIEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACBGNvaW4McmVkZWVtX2Z1"
            + "bmRzAQcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgNzdWkDU1VJAAEBAAADAAECAAACAAEBAQABAQMCAAAAAQIAVOgN"
            + "dteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rIBDdyh99/rzDW4oSOGYNrNUGIRFhTBGMzWzRuglYulz/M3LOUTAAAAACAASOF/"
            + "fcVbY7t8CLZ8E12/cY/ivlUFTpbpL/xulAk4DFToDXbXkMJ39aRPPOkvU9JvWJSJK/OV3uY3WYiHa+ay7gIAAAAAAADAxi0AAAAA"
            + "AAA="

        #expect(transactionBytes == expectedTransactionBytes)
    }

    @Test
    func testTokenTransactionWithCoinsAndAddressBalanceWithdrawal() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        try sut.update(
            coins: [Self.makeSuiCoin(balance: 1.1), Self.makeUSDCCoin(balance: 0.5)],
            balances: [Self.makeUSDCBalance(addressBalance: 30)]
        )

        let transaction = Self.makeTokenTransaction(walletAddress: walletAddress)
        let transactionBytes = try sut.buildTransaction(transaction: transaction, serviceInfo: Self.serviceInfo)

        let expectedTransactionBytes = "AAAEAQBB4LZd5jlHL3Es176QPchaFfgiFDiRGmG3VN7UCOPoJl7RzxQAAAAAIMhSn7Jnyoi/+ON+BzXO30MXGQen2v3hork6Wkq1"
            + "BWK6AgBg4xYAAAAAAAAHoex/wApvQNuWk60UFdDBk605BklEKM8lJiEDe9cRfikEdXNkYwRVU0RDAAAACICEHgAAAAAAACBU6A12"
            + "15DCd/WkTzzpL1PSb1iUiSvzld7mN1mIh2vmsgQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIEY29pbgxyZWRlZW1f"
            + "ZnVuZHMBB6Hsf8AKb0DblpOtFBXQwZOtOQZJRCjPJSYhA3vXEX4pBHVzZGMEVVNEQwABAQEAAwEAAAECAAACAQAAAQECAAEBAwIA"
            + "AAABAwBU6A1215DCd/WkTzzpL1PSb1iUiSvzld7mN1mIh2vmsgEN3KH33+vMNbihI4Zg2s1QYhEWFMEYzNbNG6CVi6XP8zcs5RMA"
            + "AAAAIABI4X99xVtju3wItnwTXb9xj+K+VQVOlukv/G6UCTgMVOgNdteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rLoAwAAAAAA"
            + "AOCwRgAAAAAAAA=="

        #expect(transactionBytes == expectedTransactionBytes)
    }

    @Test
    func testTokenTransactionFromAddressBalancesOnly() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        try sut.update(coins: [], balances: [Self.makeSuiBalance(addressBalance: 1), Self.makeUSDCBalance(addressBalance: 30)])

        let transaction = Self.makeTokenTransaction(walletAddress: walletAddress)
        let transactionBytes = try sut.buildTransaction(transaction: transaction, serviceInfo: Self.serviceInfo)

        let expectedTransactionBytes = "AAACAgCAhB4AAAAAAAAHoex/wApvQNuWk60UFdDBk605BklEKM8lJiEDe9cRfikEdXNkYwRVU0RDAAAAIFToDXbXkMJ39aRPPOkv"
            + "U9JvWJSJK/OV3uY3WYiHa+ayAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgRjb2luDHJlZGVlbV9mdW5kcwEHoex/"
            + "wApvQNuWk60UFdDBk605BklEKM8lJiEDe9cRfikEdXNkYwRVU0RDAAEBAAABAQIAAAEBAFToDXbXkMJ39aRPPOkvU9JvWJSJK/OV"
            + "3uY3WYiHa+ayAFToDXbXkMJ39aRPPOkvU9JvWJSJK/OV3uY3WYiHa+ay6AMAAAAAAADgsEYAAAAAAAIBDAUAAAAAAAABDQUAAAAA"
            + "AAAAACA1g0qKwXykj7FKyPmcF8mHR+ld0HKUrkGkazgiRqRJmyoAAAA="

        #expect(transactionBytes == expectedTransactionBytes)
    }

    @Test
    func testMaxCoinBuildForInspectKeepsAddressBalanceWithdrawal() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: [Self.makeSuiCoin(balance: 0.01)], balances: [Self.makeSuiBalance(addressBalance: 1)])

        let maxAmount = Amount(with: Self.suiBlockchain, type: .coin, value: 1.01)
        let receivedTransactionString = try sut.buildForInspect(
            amount: maxAmount,
            destination: walletAddress,
            referenceGasPrice: 1000,
            serviceInfo: Self.serviceInfo
        )

        let expectedTransactionString = "AAAEAQAN3KH33+vMNbihI4Zg2s1QYhEWFMEYzNbNG6CVi6XP8zcs5RMAAAAAIABI4X99xVtju3wItnwTXb9xj+K+VQVOlukv/G6U"
            + "CTgMAgABAAAAAAAAAAAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDc3VpA1NVSQAAAAiBlpgAAAAAAAAgVOgNdteQ"
            + "wnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rIEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACBGNvaW4McmVkZWVtX2Z1"
            + "bmRzAQcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgNzdWkDU1VJAAEBAQADAQAAAQIAAAIBAAABAQIAAQEDAgAAAAED"
            + "AFToDXbXkMJ39aRPPOkvU9JvWJSJK/OV3uY3WYiHa+ayAFToDXbXkMJ39aRPPOkvU9JvWJSJK/OV3uY3WYiHa+ay6AMAAAAAAAD/"
            + "yZo7AAAAAAIBDAUAAAAAAAABDQUAAAAAAAAAACA1g0qKwXykj7FKyPmcF8mHR+ld0HKUrkGkazgiRqRJmyoAAAA="

        #expect(receivedTransactionString == expectedTransactionString)
    }

    @Test
    func testCoinBuildForInspectSkipsAddressBalanceWhenCoinsCoverTransfer() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: [Self.makeSuiCoin(balance: 2)], balances: [Self.makeSuiBalance(addressBalance: 0.1)])

        let receivedTransactionString = try sut.buildForInspect(
            amount: Amount(with: Self.suiBlockchain, type: .coin, value: 0.5),
            destination: walletAddress,
            referenceGasPrice: 1000,
            serviceInfo: Self.serviceInfo
        )

        let expectedTransactionString = "AAACAAgAZc0dAAAAAAAgVOgNdteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rICAgABAQAAAQEDAAAAAAEBAFToDXbXkMJ39aRP"
            + "POkvU9JvWJSJK/OV3uY3WYiHa+ayAQ3cofff68w1uKEjhmDazVBiERYUwRjM1s0boJWLpc/zNyzlEwAAAAAgAEjhf33FW2O7fAi2"
            + "fBNdv3GP4r5VBU6W6S/8bpQJOAxU6A1215DCd/WkTzzpL1PSb1iUiSvzld7mN1mIh2vmsugDAAAAAAAAAC9oWQAAAAAA"

        #expect(receivedTransactionString == expectedTransactionString)
    }

    @Test
    func testCoinBuildForInspectWithdrawsAddressBalanceWhenCoinsCannotCoverGas() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: [Self.makeSuiCoin(balance: 2)], balances: [Self.makeSuiBalance(addressBalance: 0.1)])

        let receivedTransactionString = try sut.buildForInspect(
            amount: Amount(with: Self.suiBlockchain, type: .coin, value: 1.99),
            destination: walletAddress,
            referenceGasPrice: 1000,
            serviceInfo: Self.serviceInfo
        )

        let expectedTransactionString = "AAADAgAA4fUFAAAAAAAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDc3VpA1NVSQAAAAiA/Zx2AAAAAAAgVOgNdteQ"
            + "wnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rIEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACBGNvaW4McmVkZWVtX2Z1"
            + "bmRzAQcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgNzdWkDU1VJAAEBAAADAAECAAACAAEBAQABAQMCAAAAAQIAVOgN"
            + "dteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rIBDdyh99/rzDW4oSOGYNrNUGIRFhTBGMzWzRuglYulz/M3LOUTAAAAACAASOF/"
            + "fcVbY7t8CLZ8E12/cY/ivlUFTpbpL/xulAk4DFToDXbXkMJ39aRPPOkvU9JvWJSJK/OV3uY3WYiHa+ay6AMAAAAAAACAd44GAAAA"
            + "AAA="

        #expect(receivedTransactionString == expectedTransactionString)
    }

    @Test
    func testCoinBuildForInspectSelectsGasCoinsCoveringBudget() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        let suiCoins = (1 ... 2).map { Self.makeSuiCoin(balance: 1, objectIndex: $0) }
        sut.update(coins: suiCoins, balances: [Self.makeSuiBalance(addressBalance: 10)])

        let receivedTransactionString = try sut.buildForInspect(
            amount: Amount(with: Self.suiBlockchain, type: .coin, value: 3),
            destination: walletAddress,
            referenceGasPrice: 1000,
            serviceInfo: Self.serviceInfo
        )

        let expectedTransactionString = "AAADAgAAXtCyAAAAAAAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDc3VpA1NVSQAAAAgAXtCyAAAAAAAgVOgNdteQ"
            + "wnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rIEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACBGNvaW4McmVkZWVtX2Z1"
            + "bmRzAQcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgNzdWkDU1VJAAEBAAADAAECAAACAAEBAQABAQMCAAAAAQIAVOgN"
            + "dteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE3LOUTAAAAACAASOF/"
            + "fcVbY7t8CLZ8E12/cY/ivlUFTpbpL/xulAk4DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACNyzlEwAAAAAgAEjhf33F"
            + "W2O7fAi2fBNdv3GP4r5VBU6W6S/8bpQJOAxU6A1215DCd/WkTzzpL1PSb1iUiSvzld7mN1mIh2vmsugDAAAAAAAAAJQ1dwAAAAAA"

        #expect(receivedTransactionString == expectedTransactionString)
    }

    @Test
    func testCoinTransactionUsesLargestCoinAndAddressBalanceForShortfall() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        let dustCoins = (1 ... 300).map { Self.makeSuiCoin(balance: 0.001, objectIndex: $0) }
        sut.update(coins: dustCoins + [Self.makeSuiCoin(balance: 1)], balances: [Self.makeSuiBalance(addressBalance: 0.5)])

        let transaction = Self.makeTransaction(
            walletAddress: walletAddress,
            amount: Amount(with: Self.suiBlockchain, value: 1.4),
            fee: SuiFeeParameters(gasPrice: 750, gasBudget: 3000000)
        )
        let transactionBytes = try sut.buildTransaction(transaction: transaction, serviceInfo: Self.serviceInfo)

        let expectedTransactionBytes = "AAADAgDASgUYAAAAAAAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDc3VpA1NVSQAAAAgATnJTAAAAAAAgVOgNdteQ"
            + "wnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rIEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACBGNvaW4McmVkZWVtX2Z1"
            + "bmRzAQcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgNzdWkDU1VJAAEBAAADAAECAAACAAEBAQABAQMCAAAAAQIAVOgN"
            + "dteQwnf1pE886S9T0m9YlIkr85Xe5jdZiIdr5rIBDdyh99/rzDW4oSOGYNrNUGIRFhTBGMzWzRuglYulz/M3LOUTAAAAACAASOF/"
            + "fcVbY7t8CLZ8E12/cY/ivlUFTpbpL/xulAk4DFToDXbXkMJ39aRPPOkvU9JvWJSJK/OV3uY3WYiHa+ay7gIAAAAAAADAxi0AAAAA"
            + "AAA="

        #expect(transactionBytes == expectedTransactionBytes)
    }

    @Test
    func testMaxCoinTransactionMergesCoinsBeyondGasPaymentLimit() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        let suiCoins = (1 ... 300).map { Self.makeSuiCoin(balance: 0.1, objectIndex: $0) }
        sut.update(coins: suiCoins.reversed(), balances: [Self.makeSuiBalance(addressBalance: 1)])

        let transaction = Self.makeTransaction(
            walletAddress: walletAddress,
            amount: Amount(with: Self.suiBlockchain, value: try #require(Decimal(stringValue: "30.997"))),
            fee: SuiFeeParameters(gasPrice: 750, gasBudget: 3000000)
        )
        let transactionString = try sut.buildTransaction(transaction: transaction, serviceInfo: Self.serviceInfo)
        let transactionBytes = try #require(Data(base64Encoded: transactionString))

        let expectedHash = "6cddcb317b59c5d90bcce74a4faf36a9bcf7c7a050e3a4f04f359803f53c9827"

        #expect(transactionBytes.count == 22425)
        #expect(Data(SHA256.hash(data: transactionBytes)).hex() == expectedHash)
    }

    @Test
    func testTokenBuildForInspectLimitsGasPaymentForFragmentedSuiCoins() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        let suiCoins = (1 ... 300).map { Self.makeSuiCoin(balance: 0.1, objectIndex: $0) }
        sut.update(coins: suiCoins + [Self.makeUSDCCoin(balance: 5)], balances: [])

        let transactionString = try sut.buildForInspect(
            amount: Amount(with: Self.usdcToken, value: 2),
            destination: walletAddress,
            referenceGasPrice: 1000,
            serviceInfo: Self.serviceInfo
        )
        let gasData = try Self.readFullGasPayment(from: transactionString)

        #expect(gasData.budget == 25_600_000_000)
        #expect(gasData.hasMaxPaymentObjects)
    }

    @Test(arguments: [(amount: Decimal(31), addressBalance: Decimal(1)), (amount: Decimal(1), addressBalance: Decimal(0))])
    func testCoinBuildForInspectLimitsGasBudgetForFragmentedSuiCoins(amount: Decimal, addressBalance: Decimal) throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        let suiCoins = (1 ... 300).map { Self.makeSuiCoin(balance: 0.1, objectIndex: $0) }
        sut.update(coins: suiCoins, balances: [Self.makeSuiBalance(addressBalance: addressBalance)])

        let transactionString = try sut.buildForInspect(
            amount: Amount(with: Self.suiBlockchain, type: .coin, value: amount),
            destination: walletAddress,
            referenceGasPrice: 1000,
            serviceInfo: Self.serviceInfo
        )
        let gasData = try Self.readFullGasPayment(from: transactionString)

        #expect(gasData.budget == 25_600_000_000)
        #expect(gasData.hasMaxPaymentObjects)
    }

    @Test
    func testCoinGasTransactionDoesNotRequireServiceInfo() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: Self.makeCoinsWithSuiAndUsdc(), balances: [Self.makeSuiBalance(addressBalance: 0.1)])

        let transaction = Self.makeTokenTransaction(walletAddress: walletAddress)
        let transactionBytes = try sut.buildTransaction(transaction: transaction, serviceInfo: nil)

        #expect(!sut.requiresServiceInfo)
        #expect(try transactionBytes == sut.buildTransaction(transaction: transaction, serviceInfo: Self.serviceInfo))
    }

    @Test
    func testAddressBalanceGasTransactionRequiresServiceInfo() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: [], balances: [Self.makeSuiBalance(addressBalance: 2)])

        let transaction = Self.makeTransaction(
            walletAddress: walletAddress,
            amount: Amount(with: Self.suiBlockchain, value: 0.5),
            fee: SuiFeeParameters(gasPrice: 750, gasBudget: 3000000)
        )

        #expect(sut.requiresServiceInfo)

        do {
            _ = try sut.buildTransaction(transaction: transaction, serviceInfo: nil)
            #expect(Bool(false), "Expected to fail with: \(BlockchainSdkError.failedToBuildTx)")
        } catch BlockchainSdkError.failedToBuildTx {
        } catch {
            #expect(Bool(false), "Expected to fail with: \(BlockchainSdkError.failedToBuildTx), received: \(error)")
        }
    }

    @Test
    func testBuildTransactionFailsForInvalidChainIdentifier() throws {
        let (walletAddress, sut) = try Self.makeWalletAddressAndSUT()
        sut.update(coins: [], balances: [Self.makeSuiBalance(addressBalance: 2)])

        let transaction = Self.makeTransaction(
            walletAddress: walletAddress,
            amount: Amount(with: Self.suiBlockchain, value: 0.5),
            fee: SuiFeeParameters(gasPrice: 750, gasBudget: 3000000)
        )
        let serviceInfo = SuiServiceInfo(chainIdentifier: "invalid", epoch: 1292)

        do {
            _ = try sut.buildTransaction(transaction: transaction, serviceInfo: serviceInfo)
            #expect(Bool(false), "Expected to fail with: \(BlockchainSdkError.failedToBuildTx)")
        } catch BlockchainSdkError.failedToBuildTx {
            // expected error thrown
        } catch {
            #expect(Bool(false), "Expected to fail with: \(BlockchainSdkError.failedToBuildTx), received: \(error)")
        }
    }

    @Test(arguments: [
        "",
        "0x",
        "0x0054e80d76d790c277f5a44f3ce92f53d26f5894892bf395dee6375988876be6b2",
        "54e80d76d790c277f5a44f3ce92f53d26f5894892bf395dee6375988876be6b2ff",
    ])
    func testAddressRejectsEmptyAndOverlongHex(hex: String) {
        do {
            _ = try SuiTransactionData.Address(hex)
            #expect(Bool(false), "Expected to fail with: \(BlockchainSdkError.failedToBuildTx)")
        } catch BlockchainSdkError.failedToBuildTx {
        } catch {
            #expect(Bool(false), "Expected to fail with: \(BlockchainSdkError.failedToBuildTx), received: \(error)")
        }
    }

    @Test
    func testAddressPadsShortHex() throws {
        let address = try SuiTransactionData.Address("0x2")

        #expect(address.bytes == Data(repeating: 0, count: 31) + [0x02])
    }
}

// MARK: - Sample data and factory methods

extension SuiTransactionTests {
    static let suiBlockchain = Blockchain.sui(curve: .ed25519_slip0010, testnet: false)
    static let suiCoinDecimalValue = Decimal(1_000_000_000)
    static let usdcTokenDecimalValue = Decimal(1_000_000)
    static let usdcToken = Token(
        name: "USDC",
        symbol: "USDC",
        contractAddress: "0xa1ec7fc00a6f40db9693ad1415d0c193ad3906494428cf252621037bd7117e29::usdc::USDC",
        decimalCount: 6,
        id: "usd-coin"
    )
    static let serviceInfo = SuiServiceInfo(chainIdentifier: "4btiuiMPvEENsttpZC7CZ53DruC3MAgfznDbASZ7DR6S", epoch: 1292)

    private static func makeSUT(walletAddress: String, publicKey: Wallet.PublicKey) -> SuiTransactionBuilder {
        SuiTransactionBuilder(walletAddress: walletAddress, publicKey: publicKey, decimalValue: suiCoinDecimalValue, nonceProvider: { 42 })
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

    private static func makeTransaction(walletAddress: String, amount: Amount, fee: SuiFeeParameters) -> Transaction {
        Transaction(
            amount: amount,
            fee: Fee(Amount(with: suiBlockchain, value: 0), parameters: fee),
            sourceAddress: walletAddress,
            destinationAddress: walletAddress,
            changeAddress: ""
        )
    }

    private static func makeSuiBalance(addressBalance: Decimal) -> SuiBalance {
        SuiBalance(
            coinType: .sui,
            balance: addressBalance * suiCoinDecimalValue,
            addressBalance: addressBalance * suiCoinDecimalValue
        )
    }

    private static func makeUSDCBalance(addressBalance: Decimal) throws -> SuiBalance {
        try SuiBalance(
            coinType: .init(string: usdcToken.contractAddress),
            balance: addressBalance * usdcTokenDecimalValue,
            addressBalance: addressBalance * usdcTokenDecimalValue
        )
    }

    private static func makeCoinsWithSuiAndUsdc() -> [SuiCoinObject] {
        [
            makeSuiCoin(balance: 1.1),
            makeUSDCCoin(balance: 5),
        ]
    }

    private static func makeSuiCoin(balance: Decimal, objectIndex: Int) -> SuiCoinObject {
        SuiCoinObject(
            coinType: .init(contract: "0x2", lowerID: "sui", upperID: "SUI"),
            coinObjectId: String(format: "0x%064x", objectIndex),
            version: 333786167,
            digest: "127TTe3fyhURjzUxAhByCVxb5TkQbkBiLmk8xnpiuy2b",
            balance: balance * suiCoinDecimalValue
        )
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

    private static func readFullGasPayment(from transactionString: String) throws -> (budget: UInt64, hasMaxPaymentObjects: Bool) {
        let transactionBytes = try #require(Data(base64Encoded: transactionString))

        let expirationLength = 1
        let budgetEnd = transactionBytes.count - expirationLength
        let budgetBytes = transactionBytes.subdata(in: budgetEnd - 8 ..< budgetEnd)
        let budget = budgetBytes.reversed().reduce(UInt64.zero) { $0 << 8 | UInt64($1) }

        let objectRefLength = 32 + 8 + 1 + 32
        let paymentEnd = budgetEnd - 8 - 8 - 32
        let paymentCountOffset = paymentEnd - 256 * objectRefLength - 2
        let paymentCount = transactionBytes.subdata(in: paymentCountOffset ..< paymentCountOffset + 2)

        return (budget, paymentCount == Data([0x80, 0x02]))
    }

    private static func makeWalletAddress(publicKey: Wallet.PublicKey) throws -> String {
        try AddressServiceFactory(blockchain: .sui(curve: .ed25519_slip0010, testnet: false))
            .makeAddressService()
            .makeAddress(for: publicKey, with: .default).value
    }
}
