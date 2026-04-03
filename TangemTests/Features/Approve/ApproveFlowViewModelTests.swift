//
//  ApproveFlowViewModelTests.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

import Testing
import Combine
import BlockchainSdk
import TangemUI
@testable import Tangem

@Suite("ApproveFlowViewModel")
struct ApproveFlowViewModelTests {
    // MARK: - Navigation routing

    @Test("didSendApproveTransaction is forwarded to the coordinator router")
    func didSendApproveTransaction_forwardsToRouter() {
        let (sut, env) = makeSUT()

        sut.didSendApproveTransaction()

        #expect(env.router.didSendApproveTransactionCallCount == 1)
    }

    @Test("userDidCancel is forwarded to the coordinator router")
    func userDidCancel_forwardsToRouter() {
        let (sut, env) = makeSUT()

        sut.userDidCancel()

        #expect(env.router.userDidCancelCallCount == 1)
    }

    @Test("openLearnMore is forwarded to the coordinator router")
    func openLearnMore_forwardsToRouter() {
        let (sut, env) = makeSUT()

        sut.openLearnMore()

        #expect(env.router.openLearnMoreCallCount == 1)
    }

    // MARK: - Initial state

    @Test("Initial state is .approve")
    func initialState_isApprove() {
        let (sut, _) = makeSUT()

        guard case .approve = sut.state else {
            Issue.record("Initial state should be .approve, got \(sut.state)")
            return
        }
    }

    // MARK: - Fee token selection navigation

    @Test("presentFeeTokenSelection transitions state to .feeTokenSelection when feeSelectorViewModel exists")
    func presentFeeTokenSelection_withViewModel_transitionsState() {
        let (sut, _) = makeSUT(includeFeeSelectorViewModel: true)

        sut.presentFeeTokenSelection()

        guard case .feeTokenSelection = sut.state else {
            Issue.record("State should be .feeTokenSelection after presenting, got \(sut.state)")
            return
        }
    }

    @Test("presentFeeTokenSelection is a no-op when feeSelectorViewModel is nil")
    func presentFeeTokenSelection_withoutViewModel_isNoOp() {
        let (sut, _) = makeSUT(includeFeeSelectorViewModel: false)

        sut.presentFeeTokenSelection()

        guard case .approve = sut.state else {
            Issue.record("State should remain .approve when feeSelectorViewModel is nil, got \(sut.state)")
            return
        }
    }

    @Test("dismissFeeTokenSelection returns state to .approve")
    func dismissFeeTokenSelection_returnsToApprove() {
        let (sut, _) = makeSUT(includeFeeSelectorViewModel: true)

        sut.presentFeeTokenSelection()
        guard case .feeTokenSelection = sut.state else {
            Issue.record("Precondition: should be in feeTokenSelection state")
            return
        }

        sut.dismissFeeTokenSelection()

        guard case .approve = sut.state else {
            Issue.record("State should return to .approve after dismissal, got \(sut.state)")
            return
        }
    }

    @Test("openFeeTokenSelection routes to presentFeeTokenSelection")
    func openFeeTokenSelection_presentsFeeSelectorWhenAvailable() {
        let (sut, _) = makeSUT(includeFeeSelectorViewModel: true)

        sut.openFeeTokenSelection()

        guard case .feeTokenSelection = sut.state else {
            Issue.record("openFeeTokenSelection should present fee selector, got \(sut.state)")
            return
        }
    }

    // MARK: - userDidSelectFeeToken

    @Test("userDidSelectFeeToken delegates to interactor and resets state to .approve")
    func userDidSelectFeeToken_delegatesToInteractorAndResetsState() {
        let (sut, env) = makeSUT(includeFeeSelectorViewModel: true)

        // Navigate to fee selection first
        sut.presentFeeTokenSelection()
        guard case .feeTokenSelection = sut.state else {
            Issue.record("Precondition: should be in feeTokenSelection state")
            return
        }

        let tokenItem = TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
        let stub = TokenFeeProviderStub(
            feeTokenItem: tokenItem,
            initialFee: TokenFee(option: .market, tokenItem: tokenItem, value: .success(Fee(Amount(with: .ethereum(testnet: false), value: 0.001))))
        )

        sut.userDidSelectFeeToken(tokenFeeProvider: stub)

        // State must return to .approve
        guard case .approve = sut.state else {
            Issue.record("State should return to .approve after fee token selection, got \(sut.state)")
            return
        }

        // Interactor must have been notified
        #expect(env.feeManager.updateSelectedFeeProviderCalls.count == 1)
        #expect(env.feeManager.updateFeesCalls == 1)
    }

    // MARK: - Helpers

    private struct FlowEnv {
        let router: ApproveCoordinatingMock
        let interactor: ApproveInteractor
        let feeManager: TokenFeeProvidersManagerMock
    }

    private func makeSUT(includeFeeSelectorViewModel: Bool = false) -> (ApproveFlowViewModel, FlowEnv) {
        let router = ApproveCoordinatingMock()
        let tokenItem = TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
        let fee = Fee(Amount(with: .ethereum(testnet: false), value: 0.001))
        let tokenFee = TokenFee(option: .market, tokenItem: tokenItem, value: .success(fee))
        let feeProvider = TokenFeeProviderStub(feeTokenItem: tokenItem, initialFee: tokenFee)
        let feeManager = TokenFeeProvidersManagerMock(feeProvider: feeProvider)

        let output = ApproveOutputMock()
        let allowanceService = AllowanceServiceMock()
        let dispatcher = TransactionDispatcherMock()
        let analyticsLogger = SendApproveAnalyticsLoggerMock()

        let approveData = ApproveTransactionData(
            txData: Data([0x01]),
            spender: "0xSpender",
            toContractAddress: "0xContract"
        )

        let interactor = ApproveInteractor(
            approveData: approveData,
            initialPolicy: ApprovePolicy.specified,
            approveAmount: 100,
            allowanceService: allowanceService,
            approveTransactionDispatcher: dispatcher,
            tokenFeeProvidersManager: feeManager,
            analyticsLogger: analyticsLogger,
            output: output
        )

        let settings = ApproveViewModel.Settings(
            subtitle: "Test subtitle",
            feeFooterText: "Test footer",
            tokenItem: tokenItem,
            selectedPolicy: ApprovePolicy.specified,
            tangemIconProvider: TangemIconProviderStub()
        )

        let approveInput = ApproveViewModel.Input(
            settings: settings,
            feeFormatter: FeeFormatterStub(),
            interactor: interactor
        )

        let approveViewModel = ApproveViewModel(input: approveInput)

        var feeSelectorViewModel: FeeSelectorTokensViewModel?
        if includeFeeSelectorViewModel {
            feeSelectorViewModel = FeeSelectorTokensViewModel(tokensDataProvider: interactor)
        }

        let viewModel = ApproveFlowViewModel(
            approveViewModel: approveViewModel,
            router: router,
            feeSelectorViewModel: feeSelectorViewModel,
            interactor: interactor,
            confirmTransactionPolicy: ConfirmTransactionPolicyStub()
        )

        let env = FlowEnv(router: router, interactor: interactor, feeManager: feeManager)

        return (viewModel, env)
    }
}

// MARK: - Minimal stubs for ViewModel dependencies

private struct TangemIconProviderStub: TangemIconProvider {
    func getMainButtonIcon() -> MainButton.Icon? { nil }
}

private struct FeeFormatterStub: FeeFormatter {
    func formattedFeeComponents(
        fee: Decimal,
        currencySymbol: String,
        currencyId: String?,
        isFeeApproximate: Bool,
        formattingOptions: BalanceFormattingOptions
    ) -> FormattedFeeComponents {
        FormattedFeeComponents(cryptoFee: "", fiatFee: nil)
    }

    func format(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> String { "" }
}

private struct ConfirmTransactionPolicyStub: ConfirmTransactionPolicy {
    var needsHoldToConfirm: Bool { false }
}
