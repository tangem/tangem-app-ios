//
//  CommonTokenFeeProvidersManagerTronDEXTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import TangemExpress
@testable import Tangem

@Suite("CommonTokenFeeProvidersManager — Tron DEX fee", .serialized)
struct CommonTokenFeeProvidersManagerTronDEXTests {
    private let tronTokenItem: TokenItem = .blockchain(.init(.tron(testnet: false), derivationPath: nil))

    @Test("transactionFee maps the Tron DEX input and returns the loaded fee")
    func transactionFee_tronDex_mapsInputAndReturnsFee() async throws {
        let loadedFee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: Decimal(string: "2.345678")!))
        let provider = makeProvider(loadedFee: loadedFee)
        let sut = CommonTokenFeeProvidersManager(feeProviders: [provider], initialSelectedProvider: provider, ownerAddress: nil)

        let rawTransactionHex = "0x" + TronDEXFixtures.liFiRawTransactionHex
        let result = try await sut.transactionFee(data: .dex(data: makeExpressTransactionData(txData: rawTransactionHex)))

        guard case .contractCall(let parsedCall) = try TronRawTransactionParser()
            .parse(rawTransaction: Data(hexString: rawTransactionHex)) else {
            Issue.record("Expected the fixture to parse as a contract call")
            return
        }
        let embeddedCallData = parsedCall.callData
        let expectedInput = TokenFeeProviderInputData.dex(.tron(request: TronFeeRequestData(
            amount: BSDKAmount(with: .tron(testnet: false), type: .coin, value: .zero),
            destination: "TU3ymitEKCWQFtASkEeHaPb8NfZcJtCHLt",
            callData: embeddedCallData,
            memo: nil,
            otherNativeFee: Decimal(string: "0.3")!
        )))

        #expect(provider.setupCalls == [expectedInput])
        #expect(provider.updateFeesCallCount == 1)
        #expect(result.amount.value == loadedFee.amount.value)
    }

    @Test(
        "transactionFee forwards the embedded memo, falling back to extraDestinationId",
        arguments: [
            (TronDEXFixtures.swapKitRawTransactionHex, "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", nil, TronDEXFixtures.swapKitMemo),
            (TronDEXFixtures.swapKitRawTransactionHex, "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", "fallback-extra-id", TronDEXFixtures.swapKitMemo),
            (TronDEXFixtures.liFiRawTransactionHex, "TU3ymitEKCWQFtASkEeHaPb8NfZcJtCHLt", "fallback-extra-id", "fallback-extra-id"),
            (TronDEXFixtures.liFiRawTransactionHex, "TU3ymitEKCWQFtASkEeHaPb8NfZcJtCHLt", "", nil),
        ] as [(String, String, String?, String?)]
    )
    func transactionFee_tronDex_forwardsMemo(
        rawTransactionHex: String,
        destinationAddress: String,
        extraDestinationId: String?,
        expectedMemo: String?
    ) async throws {
        let loadedFee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: 1))
        let provider = makeProvider(loadedFee: loadedFee)
        let sut = CommonTokenFeeProvidersManager(feeProviders: [provider], initialSelectedProvider: provider, ownerAddress: nil)

        _ = try await sut.transactionFee(
            data: .dex(data: makeExpressTransactionData(
                destinationAddress: destinationAddress,
                txData: "0x" + rawTransactionHex,
                extraDestinationId: extraDestinationId
            ))
        )

        guard case .dex(.tron(let request)) = provider.setupCalls.first else {
            Issue.record("Expected a Tron DEX input, got \(String(describing: provider.setupCalls.first))")
            return
        }

        #expect(request.memo == expectedMemo)
    }

    @Test("transactionFee maps a plain coin transfer to a callData-free input")
    func transactionFee_tronDexTransfer_mapsToTransferInput() async throws {
        let loadedFee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: 1))
        let provider = makeProvider(loadedFee: loadedFee)
        let sut = CommonTokenFeeProvidersManager(feeProviders: [provider], initialSelectedProvider: provider, ownerAddress: nil)

        _ = try await sut.transactionFee(
            data: .dex(data: makeExpressTransactionData(
                destinationAddress: "TKJMd8JF5hevd2TQeSKvJzwQKgpRQVHpr6",
                txValue: 50,
                txData: TronDEXFixtures.swapKitTransferRawTransactionHex
            ))
        )

        let expectedInput = TokenFeeProviderInputData.dex(.tron(request: TronFeeRequestData(
            amount: BSDKAmount(with: .tron(testnet: false), type: .coin, value: 50),
            destination: "TKJMd8JF5hevd2TQeSKvJzwQKgpRQVHpr6",
            callData: nil,
            memo: nil,
            otherNativeFee: Decimal(string: "0.3")!
        )))

        #expect(provider.setupCalls == [expectedInput])
        #expect(provider.updateFeesCallCount == 1)
    }

    /// `Data(hexString:)` decodes invalid hex to empty data, so empty and malformed strings
    /// are rejected the same way as a missing one.
    @Test(
        "transactionFee throws when txData is missing, empty or not hex",
        arguments: [nil, "", "not-a-hex-string"] as [String?]
    )
    func transactionFee_tronDexWithoutUsableTxData_throwsTransactionDataNotFound(txData: String?) async {
        let loadedFee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: 1))
        let provider = makeProvider(loadedFee: loadedFee)
        let sut = CommonTokenFeeProvidersManager(feeProviders: [provider], initialSelectedProvider: provider, ownerAddress: nil)

        do {
            _ = try await sut.transactionFee(data: .dex(data: makeExpressTransactionData(txData: txData)))
            Issue.record("Expected transactionFee to throw transactionDataNotFound")
        } catch ExpressProviderError.transactionDataNotFound {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(provider.setupCalls.isEmpty)
    }

    @Test("transactionFee throws when the provider transaction was built for another owner")
    func transactionFee_tronDexForeignOwner_throwsOwnerMismatch() async {
        let loadedFee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: 1))
        let provider = makeProvider(loadedFee: loadedFee)
        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [provider],
            initialSelectedProvider: provider,
            ownerAddress: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF"
        )

        do {
            _ = try await sut.transactionFee(
                data: .dex(data: makeExpressTransactionData(txData: "0x" + TronDEXFixtures.liFiRawTransactionHex))
            )
            Issue.record("Expected transactionFee to throw ownerAddressMismatch")
        } catch TronDEXTransactionValidationError.ownerAddressMismatch {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(provider.setupCalls.isEmpty)
    }

    @Test("transactionFee accepts the provider transaction when the owner matches")
    func transactionFee_tronDexMatchingOwner_mapsInput() async throws {
        let loadedFee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: 1))
        let provider = makeProvider(loadedFee: loadedFee)
        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [provider],
            initialSelectedProvider: provider,
            ownerAddress: "TRbRnXcKrA9bkx1nnP3Z6pLJ2SDPdwRnBW"
        )

        _ = try await sut.transactionFee(
            data: .dex(data: makeExpressTransactionData(txData: "0x" + TronDEXFixtures.liFiRawTransactionHex))
        )

        #expect(provider.setupCalls.count == 1)
        #expect(provider.updateFeesCallCount == 1)
    }

    @Test("transactionFee throws when txData is not a raw Tron transaction")
    func transactionFee_tronDexWithPlainCalldata_throwsParserError() async {
        let loadedFee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: 1))
        let provider = makeProvider(loadedFee: loadedFee)
        let sut = CommonTokenFeeProvidersManager(feeProviders: [provider], initialSelectedProvider: provider, ownerAddress: nil)

        do {
            _ = try await sut.transactionFee(data: .dex(data: makeExpressTransactionData(txData: "a9059cbb00ff")))
            Issue.record("Expected transactionFee to throw a parser error")
        } catch is TronRawTransactionParserError {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(provider.setupCalls.isEmpty)
    }
}

// MARK: - Helpers

private extension CommonTokenFeeProvidersManagerTronDEXTests {
    func makeProvider(loadedFee: BSDKFee) -> ControllableTokenFeeProviderStub {
        ControllableTokenFeeProviderStub(
            feeTokenItem: tronTokenItem,
            state: .available([.market: loadedFee]),
            balance: .loaded(100),
            selectedTokenFee: TokenFee(option: .market, tokenItem: tronTokenItem, value: .success(loadedFee))
        )
    }

    func makeExpressTransactionData(
        destinationAddress: String = "TU3ymitEKCWQFtASkEeHaPb8NfZcJtCHLt",
        txValue: Decimal = .zero,
        txData: String?,
        extraDestinationId: String? = nil
    ) -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: "TRbRnXcKrA9bkx1nnP3Z6pLJ2SDPdwRnBW",
            destinationAddress: destinationAddress,
            extraDestinationId: extraDestinationId,
            txValue: txValue,
            txData: txData,
            otherNativeFee: Decimal(string: "0.3")!,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )
    }
}
