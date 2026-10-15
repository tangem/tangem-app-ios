//
//  SwapModelCEXDepositFeeTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemFoundation
import Testing
@testable import TangemExpress
@testable import Tangem

@Suite("SwapModel CEX deposit fee")
struct SwapModelCEXDepositFeeTests {
    @Test("a coin fee is sent as the user saw it")
    func coinFee_doesNotRequote() async throws {
        let shown = BSDKFee(BSDKAmount(with: .ethereum(testnet: false), value: 1))
        let env = makeEnvironment(shown: shown, quoted: shown)

        let fee = try await env.sut.cexDepositFee(
            provider: env.provider,
            data: makeTransactionData(),
            preview: makePreview(fee: shown),
            source: env.source
        )

        #expect(fee.amount.value == 1)
        #expect(env.manager.transactionFeeDataCalls.isEmpty)
    }

    @Test("a coin fee chosen after the preview is the one that is signed")
    func coinFee_changedAfterPreview_signsShownFee() async throws {
        let previewFee = BSDKFee(BSDKAmount(with: .ethereum(testnet: false), value: 1))
        let shown = BSDKFee(BSDKAmount(with: .ethereum(testnet: false), value: 3))
        let env = makeEnvironment(shown: shown, quoted: shown)

        let fee = try await env.sut.cexDepositFee(
            provider: env.provider,
            data: makeTransactionData(),
            preview: makePreview(fee: previewFee),
            source: env.source
        )

        #expect(fee.amount.value == 3)
        #expect(env.manager.transactionFeeDataCalls.isEmpty)
    }

    @Test(
        "a higher Tron gasless deposit quote is not signed",
        .enabled(if: FeatureProvider.isAvailable(.tronGaslessCEX))
    )
    func tronGaslessFeeIncreased_throws() async throws {
        let shown = makeGaslessFee(compensation: 1, quoteId: "shown")
        let quoted = makeGaslessFee(compensation: Decimal(string: "2.5")!, quoteId: "quoted")
        let env = makeEnvironment(shown: shown, quoted: quoted)

        do {
            _ = try await env.sut.cexDepositFee(
                provider: env.provider,
                data: makeTransactionData(),
                preview: makePreview(fee: shown),
                source: env.source
            )
            Issue.record("Expected informationRelevanceServiceFeeWasIncreased")
        } catch TransactionDispatcherResult.Error.informationRelevanceServiceFeeWasIncreased {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(env.manager.transactionFeeDataCalls.count == 1)
    }

    @Test(
        "an equal Tron gasless deposit quote is the fee that is signed",
        .enabled(if: FeatureProvider.isAvailable(.tronGaslessCEX))
    )
    func tronGaslessFeeUnchanged_returnsQuotedFee() async throws {
        let shown = makeGaslessFee(compensation: Decimal(string: "2.5")!, quoteId: "shown")
        let quoted = makeGaslessFee(compensation: Decimal(string: "2.5")!, quoteId: "quoted")
        let env = makeEnvironment(shown: shown, quoted: quoted)

        let fee = try await env.sut.cexDepositFee(
            provider: env.provider,
            data: makeTransactionData(),
            preview: makePreview(fee: shown),
            source: env.source
        )

        let parameters = try #require(fee.parameters as? TronGaslessFeeParameters)
        #expect(parameters.quoteId == "quoted")
        #expect(env.manager.transactionFeeDataCalls.count == 1)
    }

    @Test(
        "a Tron gasless quote in another fee token is not signed",
        .enabled(if: FeatureProvider.isAvailable(.tronGaslessCEX))
    )
    func tronGaslessFeeCurrencyChanged_throws() async throws {
        let shown = makeGaslessFee(compensation: 1, quoteId: "shown")
        let quoted = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: 1))
        let env = makeEnvironment(shown: shown, quoted: quoted)

        do {
            _ = try await env.sut.cexDepositFee(
                provider: env.provider,
                data: makeTransactionData(),
                preview: makePreview(fee: shown),
                source: env.source
            )
            Issue.record("Expected informationRelevanceServiceFeeWasIncreased")
        } catch TransactionDispatcherResult.Error.informationRelevanceServiceFeeWasIncreased {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test(
        "a Tron gasless deposit quote stays the fee the user saw",
        .enabled(if: !FeatureProvider.isAvailable(.tronGaslessCEX))
    )
    func tronGaslessFee_keepsShownFee() async throws {
        let shown = makeGaslessFee(compensation: 1, quoteId: "shown")
        let previewFee = makeGaslessFee(compensation: Decimal(string: "0.5")!, quoteId: "preview")
        let quoted = makeGaslessFee(compensation: Decimal(string: "2.5")!, quoteId: "quoted")
        let env = makeEnvironment(shown: shown, quoted: quoted)

        let fee = try await env.sut.cexDepositFee(
            provider: env.provider,
            data: makeTransactionData(),
            preview: makePreview(fee: previewFee),
            source: env.source
        )

        let parameters = try #require(fee.parameters as? TronGaslessFeeParameters)
        #expect(parameters.quoteId == "shown")
        #expect(env.manager.transactionFeeDataCalls.isEmpty)
    }
}

// MARK: - Environment

private extension SwapModelCEXDepositFeeTests {
    struct Environment {
        let sut: SwapModel
        let provider: ExpressAvailableProvider
        let manager: TokenFeeProvidersManagerMock
        let source: SwapableTokenStub
    }

    func makeEnvironment(shown: BSDKFee, quoted: BSDKFee) -> Environment {
        let tokenItem = feeTokenItem
        let manager = TokenFeeProvidersManagerMock(
            feeProvider: TokenFeeProviderStub(
                feeTokenItem: tokenItem,
                initialFee: TokenFee(option: .market, tokenItem: tokenItem, value: .success(shown))
            )
        )
        manager.transactionFeeResult = .success(quoted)
        let source = SwapableTokenStub(
            blockchain: .tron(testnet: false),
            transactionValidator: SucceedingTransactionValidator()
        )
        let sut = SwapModel(
            parameters: .from(source, pair: .fixed(receive: SwapableTokenStub(blockchain: .ethereum(testnet: false)))),
            expressManager: ExpressManagerDummy(),
            swapRepository: SwapRepositoryStub(),
            expressPendingTransactionRepository: ExpressPendingTransactionRepositoryStub(),
            expressAPIProvider: ExpressAPIProviderStub(),
            expressUserWalletId: UserWalletId(value: Data()),
            analyticsLogger: SendAnalyticsLoggerStub(),
            autoupdatingTimer: AutoupdatingTimer(),
            pairUpdateHandler: PairUpdateHandlerDummy(),
            balanceRestrictionFeatureChecker: BalanceRestrictionCheckerDummy(),
            shouldStartInitialLoading: false
        )

        return Environment(
            sut: sut,
            provider: ExpressAvailableProviderFixture.make(state: .idle, expressFeeProvider: manager),
            manager: manager,
            source: source
        )
    }

    func makePreview(fee: BSDKFee) -> SwapModel.PreviewCEXState {
        SwapModel.PreviewCEXState(
            quote: SwapModel.Quote(fromAmount: 10, expectAmount: 20, highPriceImpact: nil),
            subtractFee: SwapModel.SubtractFee(feeTokenItem: feeTokenItem, subtractFee: 0),
            fee: fee,
            isExemptFee: false,
            notification: nil
        )
    }

    func makeTransactionData() -> ExpressTransactionData {
        ExpressTransactionDataFixture.make(
            fromAmount: 10,
            toAmount: 20,
            transactionType: .send,
            sourceAddress: "TSourceAddress",
            destinationAddress: "TCEXDepositAddress",
            txValue: 10,
            payInAddress: "TCEXDepositAddress"
        )
    }

    var feeTokenItem: TokenItem {
        .token(usdt, .init(.tron(testnet: false), derivationPath: nil))
    }

    var usdt: Token {
        Token(
            name: "USDT",
            symbol: "USDT",
            contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            decimalCount: 6
        )
    }

    func makeGaslessFee(compensation: Decimal, quoteId: String) -> BSDKFee {
        let parameters = TronGaslessFeeParameters(
            quoteId: quoteId,
            request: TronGaslessQuoteRequest(
                sourceAddress: "TSourceAddress",
                destinationAddress: "TSourceAddress",
                tokenContractAddress: usdt.contractAddress,
                amountRaw: "10000000",
                feeTokenContractAddress: usdt.contractAddress
            ),
            feeRecipient: "TFeeRecipient",
            compensationToken: usdt.contractAddress,
            compensationAmountRaw: "1000000",
            expiresAt: Date(timeIntervalSince1970: 0),
            energy: 1,
            bandwidth: 1,
            trxCost: "1"
        )
        return BSDKFee(BSDKAmount(with: usdt, value: compensation), parameters: parameters)
    }
}

// MARK: - Stubs

private struct SucceedingTransactionValidator: SendTransactionValidator {
    func validate(amount: Amount) throws {}
    func validate(amount: Amount, fee: Fee) throws {}
    func validate(amount: Amount, fee: Fee, builtBy: SendTransactionBuilder) throws {}
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {}
}

private actor ExpressManagerDummy: ExpressManager {
    func getCurrentPair() -> ExpressManagerSwappingPair? { nil }
    func getAmountType() -> ExpressAmountType? { nil }
    func getSlippage() -> Decimal? { nil }
    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState { .idle }
    func update(amountType: ExpressAmountType?) async throws -> ExpressManagerState { .idle }
    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState { .idle }
    func update(slippage: Decimal?) async -> ExpressManagerState { .idle }
    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState { .idle }
    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState { .idle }

    func requestData() async throws -> ExpressTransactionData {
        fatalError("Unused in tests")
    }
}

private final class PairUpdateHandlerDummy: SwapPairUpdateHandler {
    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        .providers
    }

    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState {
        .idle
    }
}

private final class BalanceRestrictionCheckerDummy: SwapBalanceRestrictionFeatureChecker {
    func swapTotalBalanceRestriction(for token: SendSourceToken) async throws -> SwapBalanceRestriction { .none }
}
