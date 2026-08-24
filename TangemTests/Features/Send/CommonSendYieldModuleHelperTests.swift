//
//  CommonSendYieldModuleHelperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemExpress
import TangemFoundation
import TangemTestKit
@testable import Tangem

@Suite("CommonSendYieldModuleHelper")
final class CommonSendYieldModuleHelperTests: LeakTrackingTestSuite {
    // MARK: - Swap branch

    @Test("Wraps a router call into the yield module swap call")
    func routerCalldataIsWrappedIntoYieldSwapCall() async throws {
        let registry = SwapExecutionRegistrySpy()
        let sut = makeSUT(swapExecutionRegistry: registry)

        let result = try await sut.yieldModuleTransactionData(
            data: makeExpressTransactionData(destinationAddress: routerAddress, txData: routerCalldata),
            provider: makeProvider(),
            spender: spenderAddress
        )

        let expectedTxData = [
            "0x4c3f521d",
            "000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            "00000000000000000000000000000000000000000000000000000000004c4b40",
            "0000000000000000000000001111111254eeb25477b68fb85ed929f73a960582",
            "000000000000000000000000000000000022d473030f116ddee9f6b43ac78ba3",
            "00000000000000000000000000000000000000000000000000000000000000a0",
            "0000000000000000000000000000000000000000000000000000000000000024",
            "12aa3caf0000000000000000000000005141b82f5ffda4c6fe1e372978f1c5427640a190",
            String(repeating: "0", count: 56),
        ].joined()

        #expect(result.destinationAddress == yieldContractAddress)
        #expect(result.txData == expectedTxData)
        #expect(registry.checkedSpenders == [spenderAddress])
        #expect(registry.checkedTargets == [routerAddress])
    }

    @Test("Rejects a router call when the quote carries no allowance contract")
    func routerCalldataWithoutSpenderThrowsSpenderNotFound() async {
        let sut = makeSUT()

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(destinationAddress: routerAddress, txData: routerCalldata),
                provider: makeProvider(),
                spender: nil
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.spenderNotFound)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.spenderNotFound) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Rejects a router call whose spender the execution registry denies")
    func deniedSpenderThrowsSpenderNotAllowed() async {
        let sut = makeSUT(swapExecutionRegistry: SwapExecutionRegistrySpy(isSpenderAllowed: false))

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(destinationAddress: routerAddress, txData: routerCalldata),
                provider: makeProvider(),
                spender: spenderAddress
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.spenderNotAllowed)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.spenderNotAllowed) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Rejects a router call whose target the execution registry denies")
    func deniedTargetThrowsTargetNotAllowed() async {
        let sut = makeSUT(swapExecutionRegistry: SwapExecutionRegistrySpy(isTargetAllowed: false))

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(destinationAddress: routerAddress, txData: routerCalldata),
                provider: makeProvider(),
                spender: spenderAddress
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.targetNotAllowed)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.targetNotAllowed) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Rejects a router call when the execution registry is missing")
    func missingExecutionRegistryThrowsSwapExecutionRegistryUnavailable() async {
        let sut = makeSUT(swapExecutionRegistry: nil)

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(destinationAddress: routerAddress, txData: routerCalldata),
                provider: makeProvider(),
                spender: spenderAddress
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.swapExecutionRegistryUnavailable)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.swapExecutionRegistryUnavailable) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Rejects a quote whose amount cannot be expressed in the smallest token unit")
    func negativeFromAmountThrowsAmountInInvalid() async {
        let sut = makeSUT()

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(
                    destinationAddress: routerAddress,
                    txData: routerCalldata,
                    fromAmount: -5
                ),
                provider: makeProvider(),
                spender: spenderAddress
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.amountInInvalid)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.amountInInvalid) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Send branch

    @Test("Re-encodes a plain transfer of the swapped token as the yield module send call")
    func transferCalldataIsReEncodedAsYieldSendCall() async throws {
        let registry = SwapExecutionRegistrySpy()
        let sut = makeSUT(swapExecutionRegistry: registry)

        let result = try await sut.yieldModuleTransactionData(
            data: makeExpressTransactionData(destinationAddress: tokenContractAddress, txData: transferCalldata),
            provider: makeProvider(),
            spender: nil
        )

        let expectedTxData = [
            "0x0779afe6",
            "000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            "000000000000000000000000d8da6bf26964af9d7eed9e03e53415d37aa96045",
            "00000000000000000000000000000000000000000000000000000000004c4b40",
        ].joined()

        #expect(result.destinationAddress == yieldContractAddress)
        #expect(result.txData == expectedTxData)
        #expect(registry.checkedSpenders.isEmpty)
        #expect(registry.checkedTargets.isEmpty)
    }

    @Test("Recognizes the swapped token contract case-insensitively")
    func transferToChecksummedTokenContractIsReEncodedAsYieldSendCall() async throws {
        let sut = makeSUT()

        let result = try await sut.yieldModuleTransactionData(
            data: makeExpressTransactionData(
                destinationAddress: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
                txData: transferCalldata
            ),
            provider: makeProvider(),
            spender: nil
        )

        #expect(result.txData?.hasPrefix(yieldSendMethodId) == true)
    }

    @Test("Keeps the payment fields of the provider transaction on the send path")
    func transferReEncodingPreservesPaymentFields() async throws {
        let sut = makeSUT()
        let providerData = makeExpressTransactionData(destinationAddress: tokenContractAddress, txData: transferCalldata)

        let result = try await sut.yieldModuleTransactionData(
            data: providerData,
            provider: makeProvider(),
            spender: nil
        )

        #expect(result.requestId == providerData.requestId)
        #expect(result.fromAmount == providerData.fromAmount)
        #expect(result.toAmount == providerData.toAmount)
        #expect(result.txValue == providerData.txValue)
        #expect(result.expressTransactionId == providerData.expressTransactionId)
        #expect(result.sourceAddress == providerData.sourceAddress)
    }

    @Test("Does not delegate the send call to the upgrade handler")
    func transferReEncodingSkipsUpgradeWrapping() async throws {
        let upgradeHandler = UpgradeHandlerSpy()
        let sut = makeSUT(upgradeHandler: upgradeHandler)

        let result = try await sut.yieldModuleTransactionData(
            data: makeExpressTransactionData(destinationAddress: tokenContractAddress, txData: transferCalldata),
            provider: makeProvider(),
            spender: nil
        )

        #expect(upgradeHandler.upgradeWrappedDataIfNeededCallCount == 0)
        #expect(result.txData?.hasPrefix(yieldSendMethodId) == true)
    }

    @Test("Delegates the swap call to the upgrade handler and returns what it produced")
    func routerCalldataGoesThroughUpgradeWrapping() async throws {
        let upgradeHandler = UpgradeHandlerSpy()
        let sut = makeSUT(upgradeHandler: upgradeHandler)

        let result = try await sut.yieldModuleTransactionData(
            data: makeExpressTransactionData(destinationAddress: routerAddress, txData: routerCalldata),
            provider: makeProvider(),
            spender: spenderAddress
        )

        #expect(upgradeHandler.upgradeWrappedDataIfNeededCallCount == 1)
        #expect(result.txData == UpgradeHandlerSpy.upgradedTxData)
    }

    @Test("Rejects a transfer whose amount differs from the quoted one")
    func transferWithMismatchedAmountThrowsAmountMismatch() async {
        let sut = makeSUT()

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(
                    destinationAddress: tokenContractAddress,
                    txData: transferCalldata,
                    fromAmount: 6
                ),
                provider: makeProvider(),
                spender: nil
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.transferAmountMismatch)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.transferAmountMismatch) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Rejects a transfer to a burn address")
    func transferToBurnAddressThrows() async {
        let sut = makeSUT()
        let burnTransferCalldata = [
            "0xa9059cbb",
            "0000000000000000000000000000000000000000000000000000000000000000",
            "00000000000000000000000000000000000000000000000000000000004c4b40",
        ].joined()

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(destinationAddress: tokenContractAddress, txData: burnTransferCalldata),
                provider: makeProvider(),
                spender: nil
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.transferCalldataMalformed)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.transferCalldataMalformed) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Rejects a transaction that carries no calldata at all")
    func missingTxDataThrowsTransactionDataNotFound() async {
        let sut = makeSUT()

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(destinationAddress: tokenContractAddress, txData: nil),
                provider: makeProvider(),
                spender: nil
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.transactionDataNotFound)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.transactionDataNotFound) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Legacy path (toggle off)

    @Test("Wraps a transfer into the swap call when transfer detection is unavailable")
    func legacyPathWrapsTransferCalldataIntoSwapCall() async throws {
        let sut = makeSUT(isTransferDetectionAvailable: false)

        let result = try await sut.yieldModuleTransactionData(
            data: makeExpressTransactionData(destinationAddress: tokenContractAddress, txData: transferCalldata),
            provider: makeProvider(),
            spender: spenderAddress
        )

        #expect(result.destinationAddress == yieldContractAddress)
        #expect(result.txData?.hasPrefix(yieldSwapMethodId) == true)
    }

    // MARK: - Error branch

    @Test("Rejects a transfer of the swapped token addressed to a router")
    func transferCalldataToRouterThrowsIndicatorsConflict() async {
        let sut = makeSUT()

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(destinationAddress: routerAddress, txData: transferCalldata),
                provider: makeProvider(),
                spender: spenderAddress
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.transferAndSwapIndicatorsConflict)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.transferAndSwapIndicatorsConflict) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Rejects a router call addressed to the swapped token contract")
    func routerCalldataToTokenContractThrowsIndicatorsConflict() async {
        let sut = makeSUT()

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(destinationAddress: tokenContractAddress, txData: routerCalldata),
                provider: makeProvider(),
                spender: spenderAddress
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.transferAndSwapIndicatorsConflict)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.transferAndSwapIndicatorsConflict) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Rejects a transfer with a truncated argument list")
    func truncatedTransferCalldataThrowsMalformed() async {
        let sut = makeSUT()
        let truncatedTransferCalldata = String(transferCalldata.dropLast(2))

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(destinationAddress: tokenContractAddress, txData: truncatedTransferCalldata),
                provider: makeProvider(),
                spender: nil
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.transferCalldataMalformed)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.transferCalldataMalformed) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    /// Dropping a single hex character keeps the byte count intact — `Data(hexString:)` turns the
    /// dangling nibble into a whole byte — so the decoder accepts the calldata with a shifted amount
    /// and only the quoted-amount check stops it.
    @Test("Rejects a transfer whose calldata lost a single hex character")
    func transferCalldataMissingOneHexCharacterIsRejected() async {
        let sut = makeSUT()
        let oddLengthTransferCalldata = String(transferCalldata.dropLast(1))

        do {
            _ = try await sut.yieldModuleTransactionData(
                data: makeExpressTransactionData(destinationAddress: tokenContractAddress, txData: oddLengthTransferCalldata),
                provider: makeProvider(),
                spender: nil
            )
            Issue.record("Expected yieldModuleSwapUnavailable(.transferAmountMismatch)")
        } catch ExpressProviderError.yieldModuleSwapUnavailable(.transferAmountMismatch) {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Provider types

    @Test("Rewrites the transaction for DEX-like providers and leaves it untouched for the rest")
    func transactionIsRewrittenOnlyForDEXLikeProviders() async throws {
        for providerType in ExpressProviderType.allCases {
            let sut = makeSUT()
            let providerData = makeExpressTransactionData(destinationAddress: routerAddress, txData: routerCalldata)

            let result = try await sut.yieldModuleTransactionData(
                data: providerData,
                provider: makeProvider(type: providerType),
                spender: spenderAddress
            )

            switch providerType {
            case .dex, .dexBridge:
                #expect(result.destinationAddress == yieldContractAddress)
                #expect(result.txData?.hasPrefix(yieldSwapMethodId) == true)
            case .cex, .onramp, .unknown:
                #expect(result.destinationAddress == providerData.destinationAddress)
                #expect(result.txData == providerData.txData)
            }
        }
    }
}

// MARK: - SUT factory

private extension CommonSendYieldModuleHelperTests {
    var tokenContractAddress: String { "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48" }
    var recipientAddress: String { "0xd8da6bf26964af9d7eed9e03e53415d37aa96045" }
    var walletAddress: String { "0x9e4d1a2b3c4d5e6f708192a3b4c5d6e7f8091a2b" }
    var routerAddress: String { "0x1111111254eeb25477b68fb85ed929f73a960582" }
    var spenderAddress: String { "0x000000000022d473030f116ddee9f6b43ac78ba3" }
    var yieldContractAddress: String { "0x4b16c5de96eb2117bbe5fd171e4d203624b014aa" }

    var yieldSwapMethodId: String { "0x4c3f521d" }
    var yieldSendMethodId: String { "0x0779afe6" }

    /// `transfer(recipientAddress, 5_000_000)`.
    var transferCalldata: String {
        [
            "0xa9059cbb",
            "000000000000000000000000d8da6bf26964af9d7eed9e03e53415d37aa96045",
            "00000000000000000000000000000000000000000000000000000000004c4b40",
        ].joined()
    }

    var routerCalldata: String {
        [
            "0x12aa3caf",
            "0000000000000000000000005141b82f5ffda4c6fe1e372978f1c5427640a190",
        ].joined()
    }

    func makeSUT(
        swapExecutionRegistry: SwapExecutionRegistrySpy? = SwapExecutionRegistrySpy(),
        upgradeHandler: UpgradeHandlerSpy? = nil,
        isTransferDetectionAvailable: Bool = true
    ) -> CommonSendYieldModuleHelper {
        let sut = CommonSendYieldModuleHelper(
            yieldContractAddress: yieldContractAddress,
            currency: ExpressWalletCurrency(
                contractAddress: tokenContractAddress,
                network: "ethereum",
                decimalCount: 6,
                symbol: "USDC"
            ),
            swapExecutionRegistryProvider: swapExecutionRegistry,
            yieldModuleUpgradeHandler: upgradeHandler,
            isTransferDetectionAvailable: isTransferDetectionAvailable
        )

        if let swapExecutionRegistry {
            trackForMemoryLeaks(swapExecutionRegistry)
        }

        if let upgradeHandler {
            trackForMemoryLeaks(upgradeHandler)
        }

        trackForMemoryLeaks(sut)

        return sut
    }

    func makeProvider(type: ExpressProviderType = .dex) -> ExpressProvider {
        ExpressProvider(
            id: "test-provider",
            name: "Test Provider",
            type: type,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        )
    }

    func makeExpressTransactionData(
        destinationAddress: String,
        txData: String?,
        fromAmount: Decimal = 5
    ) -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "test-request-id",
            fromAmount: fromAmount,
            toAmount: Decimal(string: "0.0016")!,
            expressTransactionId: "test-transaction-id",
            transactionType: .swap,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            extraDestinationId: nil,
            txValue: .zero,
            txData: txData,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )
    }
}

// MARK: - Doubles

private final class SwapExecutionRegistrySpy: YieldModuleSwapExecutionRegistryProvider {
    private let isSpenderAllowed: Bool
    private let isTargetAllowed: Bool
    private let state = OSAllocatedUnfairLock(initialState: State())

    var checkedSpenders: [String] { state.withLock { $0.checkedSpenders } }
    var checkedTargets: [String] { state.withLock { $0.checkedTargets } }

    init(isSpenderAllowed: Bool = true, isTargetAllowed: Bool = true) {
        self.isSpenderAllowed = isSpenderAllowed
        self.isTargetAllowed = isTargetAllowed
    }

    func isAllowedSpender(_ spender: String) async throws -> Bool {
        state.withLock { $0.checkedSpenders.append(spender) }
        return isSpenderAllowed
    }

    func isAllowedTarget(_ target: String) async throws -> Bool {
        state.withLock { $0.checkedTargets.append(target) }
        return isTargetAllowed
    }
}

private extension SwapExecutionRegistrySpy {
    struct State {
        var checkedSpenders: [String] = []
        var checkedTargets: [String] = []
    }
}

private final class UpgradeHandlerSpy: YieldModuleUpgradeHandler {
    static let upgradedTxData = "0xdeadbeef"

    private let callCount = OSAllocatedUnfairLock(initialState: 0)

    var upgradeWrappedDataIfNeededCallCount: Int { callCount.withLock { $0 } }

    func upgradeWrappedDataIfNeeded(_ data: ExpressTransactionData) async throws -> ExpressTransactionData {
        callCount.withLock { $0 += 1 }
        return data.replacingTxData(with: Self.upgradedTxData)
    }

    func checkSwapAvailability() async throws {}

    func refreshVersionAfterUpgrade() async throws {}

    func isUpgradeWrapped(_ data: ExpressTransactionData) -> Bool {
        false
    }
}

// MARK: - Helpers

private extension ExpressTransactionData {
    func replacingTxData(with txData: String) -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: requestId,
            fromAmount: fromAmount,
            toAmount: toAmount,
            expressTransactionId: expressTransactionId,
            transactionType: transactionType,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            extraDestinationId: extraDestinationId,
            txValue: txValue,
            txData: txData,
            otherNativeFee: otherNativeFee,
            estimatedGasLimit: estimatedGasLimit,
            externalTxId: externalTxId,
            externalTxURL: externalTxURL,
            payInAddress: payInAddress
        )
    }
}
