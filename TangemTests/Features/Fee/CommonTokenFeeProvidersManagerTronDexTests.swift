//
//  CommonTokenFeeProvidersManagerTronDexTests.swift
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
struct CommonTokenFeeProvidersManagerTronDexTests {
    private let tronTokenItem: TokenItem = .blockchain(.init(.tron(testnet: false), derivationPath: nil))

    /// The Tron DEX branch must hand the fee provider the EVM-format fields as-is:
    /// txValue as a native coin amount, txTo as the destination, txData decoded from hex,
    /// and otherNativeFee passed through untouched.
    @Test("transactionFee maps the Tron DEX input and returns the loaded fee")
    func transactionFee_tronDex_mapsInputAndReturnsFee() async throws {
        let loadedFee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: Decimal(string: "2.345678")!))
        let provider = makeProvider(loadedFee: loadedFee)
        let sut = CommonTokenFeeProvidersManager(feeProviders: [provider], initialSelectedProvider: provider)

        let result = try await sut.transactionFee(data: .dex(data: makeExpressTransactionData(txData: "a9059cbb00ff")))

        let expectedInput = TokenFeeProviderInputData.dex(.tron(
            amount: BSDKAmount(with: .tron(testnet: false), type: .coin, value: Decimal(string: "12.5")!),
            destination: "TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn",
            txData: Data([0xA9, 0x05, 0x9C, 0xBB, 0x00, 0xFF]),
            otherNativeFee: Decimal(string: "0.3")!
        ))

        #expect(provider.setupCalls == [expectedInput])
        #expect(provider.updateFeesCallCount == 1)
        #expect(result.amount.value == loadedFee.amount.value)
    }

    /// A Tron DEX transaction without calldata has no swap semantics to execute —
    /// the manager must refuse it instead of degrading into a plain transfer.
    @Test("transactionFee throws when txData is missing")
    func transactionFee_tronDexWithoutTxData_throwsTransactionDataNotFound() async {
        let loadedFee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: 1))
        let provider = makeProvider(loadedFee: loadedFee)
        let sut = CommonTokenFeeProvidersManager(feeProviders: [provider], initialSelectedProvider: provider)

        do {
            _ = try await sut.transactionFee(data: .dex(data: makeExpressTransactionData(txData: nil)))
            Issue.record("Expected transactionFee to throw transactionDataNotFound")
        } catch ExpressProviderError.transactionDataNotFound {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(provider.setupCalls.isEmpty)
    }
}

// MARK: - Helpers

private extension CommonTokenFeeProvidersManagerTronDexTests {
    func makeProvider(loadedFee: BSDKFee) -> ControllableTokenFeeProviderStub {
        ControllableTokenFeeProviderStub(
            feeTokenItem: tronTokenItem,
            state: .available([.market: loadedFee]),
            balance: .loaded(100),
            selectedTokenFee: TokenFee(option: .market, tokenItem: tronTokenItem, value: .success(loadedFee))
        )
    }

    func makeExpressTransactionData(txData: String?) -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF",
            destinationAddress: "TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn",
            extraDestinationId: nil,
            txValue: Decimal(string: "12.5")!,
            txData: txData,
            otherNativeFee: Decimal(string: "0.3")!,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )
    }
}
