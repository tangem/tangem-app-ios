//
//  CommonTokenFeeProvidersManagerApproveWithSwapTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import BigInt
@testable import TangemExpress
@testable import Tangem

@Suite("CommonTokenFeeProvidersManager — approve with swap fee", .serialized)
struct CommonTokenFeeProvidersManagerApproveWithSwapTests {
    private let ethTokenItem: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))

    /// Assembling the approve+swap fee returns the loaded combined fee as the user-facing total and exposes the approve leg the dispatcher will build separately.
    @Test("transactionFee returns the combined total and the approve leg")
    func transactionFee_combinedFee_splitsTotalAndApprove() async throws {
        let approveFee = BSDKFee(
            BSDKAmount(with: .ethereum(testnet: false), value: Decimal(string: "0.0005")!),
            parameters: EthereumLegacyFeeParameters(gasLimit: 50_000, gasPrice: 20_000_000_000)
        )
        let swapFee = BSDKFee(
            BSDKAmount(with: .ethereum(testnet: false), value: Decimal(string: "0.002")!),
            parameters: EthereumLegacyFeeParameters(gasLimit: 200_000, gasPrice: 30_000_000_000)
        )
        let combinedFee = try ApproveWithSwapFeeParameters.combinedFee(swapFee: swapFee, approveFee: approveFee)

        let sut = makeManager(loadedFee: combinedFee)

        let result = try await sut.transactionFee(
            data: .dex(data: makeExpressTransactionData()),
            allowanceOverride: makeAllowanceOverride(),
            approveData: makeApproveData()
        )

        #expect(result.total.amount.value == combinedFee.amount.value)
        #expect(result.approve.amount.value == approveFee.amount.value)
    }

    /// When the loaded fee lost its ApproveWithSwapFeeParameters (e.g. a concurrent input override), the manager refuses to assemble a misleading approve+swap fee.
    @Test("transactionFee throws feeNotFound when the loaded fee is not an approve+swap fee")
    func transactionFee_feeWithoutApproveWithSwapParameters_throwsFeeNotFound() async {
        let plainFee = BSDKFee(
            BSDKAmount(with: .ethereum(testnet: false), value: Decimal(string: "0.002")!),
            parameters: EthereumLegacyFeeParameters(gasLimit: 200_000, gasPrice: 30_000_000_000)
        )

        let sut = makeManager(loadedFee: plainFee)

        do {
            _ = try await sut.transactionFee(
                data: .dex(data: makeExpressTransactionData()),
                allowanceOverride: makeAllowanceOverride(),
                approveData: makeApproveData()
            )
            Issue.record("Expected transactionFee to throw feeNotFound")
        } catch TokenFeeProviderError.feeNotFound {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

// MARK: - Helpers

private extension CommonTokenFeeProvidersManagerApproveWithSwapTests {
    func makeManager(loadedFee: BSDKFee) -> CommonTokenFeeProvidersManager {
        let provider = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem,
            state: .available([.market: loadedFee]),
            balance: .loaded(1),
            selectedTokenFee: TokenFee(option: .market, tokenItem: ethTokenItem, value: .success(loadedFee))
        )

        return CommonTokenFeeProvidersManager(feeProviders: [provider], initialSelectedProvider: provider)
    }

    func makeAllowanceOverride() -> AllowanceOverride {
        AllowanceOverride(tokenContractAddress: "0xToken", owner: "0xOwner", spender: "0xSpender")
    }

    func makeApproveData() -> ApproveTransactionData {
        ApproveTransactionData(txData: Data([0xAB]), spender: "0xSpender", toContractAddress: "0xContract")
    }

    func makeExpressTransactionData() -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: nil,
            destinationAddress: "0xDestination",
            extraDestinationId: nil,
            txValue: Decimal(string: "1.5")!,
            txData: "0xabcdef",
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil
        )
    }
}
