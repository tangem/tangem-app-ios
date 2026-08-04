//
//  GaslessBridgeFeeSupportTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("CommonTokenFeeProvider — a token-paid fee can't cover a bridge fee")
struct GaslessBridgeFeeSupportTests {
    // MARK: - The bridge fee takes the gasless provider out

    /// A bridge provider charges its fee in the coin and expects it as the transaction value, which a
    /// gasless transaction can't carry — so paying the network fee with a token stops being an option.
    @Test("a bridge fee makes the gasless provider unsupported", arguments: SwapInput.allCases)
    func bridgeFeeMakesGaslessProviderUnsupported(input: SwapInput) {
        let sut = makeGaslessProvider()

        sut.setup(input: input.make(bridgeFee: bridgeFee))

        expectNotSupported(sut)
    }

    /// The ordinary gasless swap has no bridge fee and must stay untouched.
    @Test("a swap without a bridge fee keeps the gasless provider supported", arguments: SwapInput.allCases)
    func noBridgeFeeKeepsGaslessProviderSupported(input: SwapInput) {
        let missing = makeGaslessProvider()
        let zero = makeGaslessProvider()

        missing.setup(input: input.make(bridgeFee: nil))
        zero.setup(input: input.make(bridgeFee: 0))

        #expect(missing.state.isSupported)
        #expect(zero.state.isSupported)
    }

    // MARK: - Withdrawing the verdict

    /// A provider quotes with and without a bridge fee from one quote to the next. Nothing else clears
    /// the verdict while this provider stays unselected, so the option would never come back.
    @Test("the verdict is withdrawn once the next quote has no bridge fee", arguments: SwapInput.allCases)
    func bridgeFeeGoneGaslessProviderIsOfferedAgain(input: SwapInput) {
        let sut = makeGaslessProvider()

        sut.setup(input: input.make(bridgeFee: bridgeFee))
        expectNotSupported(sut)

        sut.setup(input: input.make(bridgeFee: nil))

        #expect(sut.state.isSupported)
    }

    /// The same leak in the other direction: a bridge-fee swap must not disable the gasless fee for the
    /// transfers, approves and CEX swaps that follow it on the same provider.
    @Test("the verdict is withdrawn for inputs that carry no bridge fee at all", arguments: PlainInput.allCases)
    func plainInputAfterBridgeFeeGaslessProviderIsOfferedAgain(input: PlainInput) {
        let sut = makeGaslessProvider()

        sut.setup(input: SwapInput.dex.make(bridgeFee: bridgeFee))
        expectNotSupported(sut)

        sut.setup(input: input.make())

        #expect(sut.state.isSupported)
    }

    /// Only this rule's own verdict may be withdrawn: an unavailability that came from the balance has
    /// to survive, otherwise a provider with no fee-token balance would look usable again.
    @Test("a balance-driven unavailability survives an input without a bridge fee")
    func zeroFeeTokenBalanceSurvivesInputWithoutBridgeFee() {
        let sut = makeGaslessProvider(feeTokenBalance: 0)

        sut.setup(input: SwapInput.dex.make(bridgeFee: nil))

        guard case .unavailable(.noTokenBalance) = sut.state else {
            Issue.record("Expected the zero-balance state to stay, got \(sut.state)")
            return
        }
    }

    /// The bridge-fee verdict overwrites the zero-balance one, so the withdrawal must restore it, not
    /// blindly go `.idle`: for an unchanged zero balance the balance publisher never re-emits.
    @Test("withdrawing the verdict restores the zero-balance state", arguments: SwapInput.allCases)
    func bridgeFeeGoneZeroBalanceStateIsRestored(input: SwapInput) {
        let sut = makeGaslessProvider(feeTokenBalance: 0)

        sut.setup(input: input.make(bridgeFee: bridgeFee))
        expectNotSupported(sut)

        sut.setup(input: input.make(bridgeFee: nil))

        guard case .unavailable(.noTokenBalance) = sut.state else {
            Issue.record("Expected the zero-balance state back, got \(sut.state)")
            return
        }
    }

    /// The same restoration on the inputs that carry no bridge fee at all.
    @Test("a plain input restores the zero-balance state as well", arguments: PlainInput.allCases)
    func plainInputAfterBridgeFeeZeroBalanceStateIsRestored(input: PlainInput) {
        let sut = makeGaslessProvider(feeTokenBalance: 0)

        sut.setup(input: SwapInput.dex.make(bridgeFee: bridgeFee))
        expectNotSupported(sut)

        sut.setup(input: input.make())

        guard case .unavailable(.noTokenBalance) = sut.state else {
            Issue.record("Expected the zero-balance state back, got \(sut.state)")
            return
        }
    }

    /// The withdrawal must read the balance of the withdrawal moment, not of the verdict moment:
    /// while the verdict holds, a recovered balance leaves `.unavailable(.notSupported)` untouched —
    /// the balance pipeline only clears `.noTokenBalance` — so only the withdrawal can bring `.idle` back.
    @Test("the verdict is withdrawn to idle once the balance has recovered")
    func bridgeFeeGoneAfterBalanceRecoveryProviderIsOfferedAgain() {
        let balanceProvider = MutableTokenBalanceProviderMock(balance: 0)
        let sut = makeGaslessProvider(balanceProvider: balanceProvider)

        sut.setup(input: SwapInput.dex.make(bridgeFee: bridgeFee))
        expectNotSupported(sut)

        balanceProvider.updateBalance(.loaded(25))
        sut.setup(input: SwapInput.dex.make(bridgeFee: nil))

        #expect(sut.state.isSupported)
    }

    // MARK: - What the rule must not touch

    @Test("the toggle off keeps the previous behaviour", arguments: SwapInput.allCases)
    func toggleOffKeepsGaslessProviderSupported(input: SwapInput) {
        let sut = makeGaslessProvider(isBridgeFeeRestrictionEnabled: false)

        sut.setup(input: input.make(bridgeFee: bridgeFee))

        #expect(sut.state.isSupported)
    }

    /// Paying the fee with the coin is exactly how a bridge fee is meant to be paid.
    @Test("a coin-paid fee provider is unaffected by a bridge fee", arguments: SwapInput.allCases)
    func coinPaidFeeProviderIsUnaffected(input: SwapInput) {
        let sut = makeCoinProvider()

        sut.setup(input: input.make(bridgeFee: bridgeFee))

        #expect(sut.state.isSupported)
    }

    // MARK: - What the swap screen ends up with

    /// The manager is what the swap flow and the fee selector ask, so the coin provider has to become
    /// the selected one — otherwise the screen would keep showing a fee that can't be paid.
    @Test("the manager moves the selection off the gasless provider")
    func managerSelectsCoinProviderWhenBridgeFeeArrives() {
        let coin = makeCoinProvider()
        let gasless = makeGaslessProvider()
        let sut = CommonTokenFeeProvidersManager(feeProviders: [coin, gasless], initialSelectedProvider: gasless, ownerAddress: nil)

        #expect(sut.selectedFeeProvider.feeTokenItem == gaslessFeeTokenItem)

        sut.update(input: SwapInput.dex.make(bridgeFee: bridgeFee))

        #expect(sut.selectedFeeProvider.feeTokenItem == coinFeeTokenItem)
        #expect(!sut.supportFeeSelection)
    }
}

// MARK: - Inputs

extension GaslessBridgeFeeSupportTests {
    /// The inputs that describe a swap, i.e. the ones a bridge fee can arrive with
    enum SwapInput: CaseIterable {
        case dexEstimate
        case dex
        case approveWithSwap

        func make(bridgeFee: Decimal?) -> TokenFeeProviderInputData {
            switch self {
            case .dexEstimate:
                .dex(.ethereumEstimate(estimatedGasLimit: 1_200_000, otherNativeFee: bridgeFee))
            case .dex:
                .dex(.ethereum(amount: coinAmount(0), destination: anyRouter, txData: anyTxData, otherNativeFee: bridgeFee))
            case .approveWithSwap:
                .approveWithSwap(
                    amount: coinAmount(bridgeFee ?? 0),
                    destination: anyRouter,
                    txData: anyTxData,
                    otherNativeFee: bridgeFee,
                    approve: ApproveWithSwapInput(
                        txData: anyTxData,
                        tokenContractAddress: anyTokenContract,
                        owner: anyOwner,
                        spender: anySpender
                    )
                )
            }
        }
    }

    /// The inputs that can't carry a bridge fee
    enum PlainInput: CaseIterable {
        case common
        case cex
        case approve

        func make() -> TokenFeeProviderInputData {
            switch self {
            case .common:
                .common(amount: 20, destination: anyRecipient)
            case .cex:
                .cex(amount: 20)
            case .approve:
                .approve(txData: anyTxData, toContractAddress: anyTokenContract)
            }
        }
    }
}

// MARK: - Helpers

private extension GaslessBridgeFeeSupportTests {
    /// What LI.FI charges for an Ethereum → BNB route
    var bridgeFee: Decimal { Decimal(string: "0.000035334")! }

    var coinFeeTokenItem: TokenItem { .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)) }

    var gaslessFeeToken: Token { Token(name: "USDC", symbol: "USDC", contractAddress: anyTokenContract, decimalCount: 6) }

    var gaslessFeeTokenItem: TokenItem { .token(gaslessFeeToken, .init(.ethereum(testnet: false), derivationPath: nil)) }

    func makeGaslessProvider(
        feeTokenBalance: Decimal = 25,
        isBridgeFeeRestrictionEnabled: Bool = true
    ) -> CommonTokenFeeProvider {
        makeGaslessProvider(
            balanceProvider: MutableTokenBalanceProviderMock(balance: feeTokenBalance),
            isBridgeFeeRestrictionEnabled: isBridgeFeeRestrictionEnabled
        )
    }

    func makeGaslessProvider(
        balanceProvider: MutableTokenBalanceProviderMock,
        isBridgeFeeRestrictionEnabled: Bool = true
    ) -> CommonTokenFeeProvider {
        let loader = CommonGaslessTokenFeeLoader(
            tokenItem: gaslessFeeTokenItem,
            feeToken: gaslessFeeToken,
            gaslessTransactionFeeProvider: GaslessTransactionFeeProviderStub(plainError: nil, yieldFee: zeroFee),
            yieldFeeContext: nil
        )

        let provider = CommonTokenFeeProvider(
            feeTokenItem: gaslessFeeTokenItem,
            tokenFeeLoader: loader,
            customFeeProvider: nil,
            feeTokenItemBalanceProvider: balanceProvider,
            supportingOptions: .all
        )
        provider.isBridgeFeeRestrictionEnabled = isBridgeFeeRestrictionEnabled

        return provider
    }

    func makeCoinProvider(isBridgeFeeRestrictionEnabled: Bool = true) -> CommonTokenFeeProvider {
        let provider = CommonTokenFeeProvider(
            feeTokenItem: coinFeeTokenItem,
            tokenFeeLoader: EthereumTokenFeeLoaderStub(),
            customFeeProvider: nil,
            feeTokenItemBalanceProvider: MutableTokenBalanceProviderMock(balance: 1),
            supportingOptions: .all
        )
        provider.isBridgeFeeRestrictionEnabled = isBridgeFeeRestrictionEnabled

        return provider
    }

    func expectNotSupported(_ provider: CommonTokenFeeProvider, sourceLocation: SourceLocation = #_sourceLocation) {
        guard case .unavailable(.notSupported) = provider.state else {
            Issue.record("Expected .unavailable(.notSupported), got \(provider.state)", sourceLocation: sourceLocation)
            return
        }

        #expect(!provider.state.isSupported, sourceLocation: sourceLocation)
    }

    var zeroFee: BSDKFee { BSDKFee(BSDKAmount(with: .ethereum(testnet: false), value: 0)) }
}

// MARK: - Shared literals

private var anyRouter: String { "0xRouter" }
private var anyRecipient: String { "0xRecipient" }
private var anyTokenContract: String { "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48" }
private var anyOwner: String { "0xOwner" }
private var anySpender: String { "0xSpender" }
private var anyTxData: Data { Data([0xAB]) }

private func coinAmount(_ value: Decimal) -> BSDKAmount {
    BSDKAmount(with: .ethereum(testnet: false), type: .coin, value: value)
}

// MARK: - Doubles

private enum StubError: Error {
    case notNeeded
}

/// A coin-paid fee loader: the DEX inputs are supported by it, so only the bridge-fee rule can take it out
private struct EthereumTokenFeeLoaderStub: EthereumTokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { throw StubError.notNeeded }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { throw StubError.notNeeded }
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee { throw StubError.notNeeded }
    func getFee(request: EthereumFeeRequestData) async throws -> [BSDKFee] { throw StubError.notNeeded }

    func getApproveWithSwapFee(request: EthereumFeeRequestData, approveInput: ApproveWithSwapInput) async throws -> [BSDKFee] {
        throw StubError.notNeeded
    }
}
