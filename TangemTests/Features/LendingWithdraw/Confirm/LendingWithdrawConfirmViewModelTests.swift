//
//  LendingWithdrawConfirmViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemTestKit
@testable import BlockchainSdk
@testable import Tangem

@Suite("Lending withdrawal confirm", .timeLimit(.minutes(1)))
@MainActor
final class LendingWithdrawConfirmViewModelTests: LeakTrackingTestSuite {
    private static let blockchain = Blockchain.ethereum(testnet: false)
    private static let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
    private static let module = "0x1111111111111111111111111111111111111111"
    private static let position = Decimal(2)

    @Test("A sent withdrawal is reported, a failed one shows the withdrawal error pop-up instead", arguments: [false, true])
    func sendOutcome(fails: Bool) async {
        let (model, token, _) = makeModel(dispatchError: fails ? Self.sendError() : nil)
        model.sourceAmountDidChanged(amount: amount("0.5"))
        model.updateFees()
        let router = LendingWithdrawConfirmRouterSpy()
        let sut = makeConfirm(model: model, token: token, router: router)

        sut.handle(.withdraw)
        await sut.withdrawTask?.value

        #expect(router.sentWithdrawals == (fails ? 0 : 1))
        #expect(await MainActor.run { sut.alert != nil } == fails)
    }

    @Test("A tap on the failed fee row estimates the fee again")
    func retryFee() {
        let (model, token, manager) = makeModel()
        model.sourceAmountDidChanged(amount: amount("0.5"))
        let sut = makeConfirm(model: model, token: token, router: LendingWithdrawConfirmRouterSpy())
        let callsBefore = manager.updateFeesCalls

        sut.handle(.retryFee)

        #expect(manager.updateFeesCalls > callsBefore)
    }

    @Test("A second tap on Withdraw while the withdrawal is being sent is ignored, so only one withdrawal goes out")
    func secondTapWhileSendingIsIgnored() async {
        let entered = TestGate()
        let release = TestGate()
        let recorder = TransactionRecorder()
        let (model, token, _) = makeModel(recorder: recorder, dispatchEntered: entered, dispatchRelease: release)
        model.sourceAmountDidChanged(amount: amount("0.5"))
        model.updateFees()
        let router = LendingWithdrawConfirmRouterSpy()
        let sut = makeConfirm(model: model, token: token, router: router)

        sut.handle(.withdraw)
        await entered.wait()
        sut.handle(.withdraw)
        release.open()
        await sut.withdrawTask?.value

        #expect(recorder.dispatchedTransactions.count == 1)
        #expect(router.sentWithdrawals == 1)
    }

    @Test("Withdraw on the confirm screen turns off once the amount is above what Aave can pay out now")
    func withdrawFollowsAvailable() async {
        let (model, token, _) = makeModel(liquidity: .success(Decimal(15) / 10))
        model.sourceAmountDidChanged(amount: amount("2"))
        let sut = makeConfirm(model: model, token: token, router: LendingWithdrawConfirmRouterSpy())
        _ = await sut.$state.values.first { $0.isWithdrawEnabled }

        await model.loadAvailableToWithdraw()

        let isWithdrawEnabled = await sut.$state.values.first { !$0.isWithdrawEnabled }?.isWithdrawEnabled
        #expect(isWithdrawEnabled == false)
    }
}

// MARK: - Helpers

private extension LendingWithdrawConfirmViewModelTests {
    func amount(_ value: String) -> SendAmount {
        SendAmount(type: .typical(crypto: Decimal(string: value), fiat: nil))
    }

    func makeToken(
        walletBalance: Decimal,
        manager: TokenFeeProvidersManagerMock,
        dispatchError: Error? = nil,
        recorder: TransactionRecorder = TransactionRecorder(),
        dispatchEntered: TestGate? = nil,
        dispatchRelease: TestGate? = nil
    ) -> SendTransferableTokenStub {
        SendTransferableTokenStub(
            blockchain: Self.blockchain,
            transactionCreator: BuildingTransactionCreatorStub(),
            tokenFeeProvidersManager: manager,
            balance: walletBalance,
            transactionDispatcherProvider: RecordingTransactionDispatcherProvider(
                recorder: recorder,
                error: dispatchError,
                entered: dispatchEntered,
                release: dispatchRelease
            )
        )
    }

    func makeFeeManager() -> TokenFeeProvidersManagerMock {
        let fee = TokenFee(
            option: .market,
            tokenItem: Self.tokenItem,
            value: .success(Fee(Amount(with: Self.blockchain, type: .coin, value: Decimal(1) / 1000)))
        )

        return TokenFeeProvidersManagerMock(feeProvider: ControllableTokenFeeProviderStub(feeTokenItem: Self.tokenItem, selectedTokenFee: fee))
    }

    func makeModel(
        liquidity: Result<Decimal, Error>? = nil,
        walletBalance: Decimal = 2,
        dispatchError: Error? = nil,
        recorder: TransactionRecorder = TransactionRecorder(),
        dispatchEntered: TestGate? = nil,
        dispatchRelease: TestGate? = nil
    ) -> (LendingWithdrawModel, SendTransferableTokenStub, TokenFeeProvidersManagerMock) {
        let manager = makeFeeManager()
        let token = makeToken(
            walletBalance: walletBalance,
            manager: manager,
            dispatchError: dispatchError,
            recorder: recorder,
            dispatchEntered: dispatchEntered,
            dispatchRelease: dispatchRelease
        )
        let model = LendingWithdrawModel(
            sourceToken: token,
            yieldModule: Self.module,
            upgradeImplementation: nil,
            positionBalance: Self.position,
            liquidityProvider: liquidity.map(LendingLiquidityProviderStub.init(result:))
        )

        return (trackForMemoryLeaks(model), token, manager)
    }

    func makeConfirm(
        model: LendingWithdrawModel,
        token: SendTransferableTokenStub,
        router: LendingWithdrawConfirmRouterSpy
    ) -> LendingWithdrawConfirmViewModel {
        let sut = LendingWithdrawConfirmViewModel(
            model: model,
            sourceToken: token,
            mailDataBuilder: CommonSendMailDataBuilder(baseDataInput: model, sourceTokenInput: model),
            router: router
        )

        return trackForMemoryLeaks(sut)
    }

    static func sendError() -> TransactionDispatcherResult.Error {
        let transaction = Transaction(
            amount: Amount(with: blockchain, type: .coin, value: 0),
            fee: Fee(Amount(with: blockchain, type: .coin, value: Decimal(1) / 1000)),
            sourceAddress: "source",
            destinationAddress: module,
            changeAddress: "source"
        )

        return .sendTxError(transaction: .transfer(transaction), error: SendTxError(error: WithdrawErrorStub()))
    }
}

// MARK: - Stubs

private struct WithdrawErrorStub: UniversalError {
    var errorCode: Int { 1 }
}

private final class LendingWithdrawConfirmRouterSpy: LendingWithdrawConfirmRoutable {
    private let state = OSAllocatedUnfairLock(initialState: 0)

    var sentWithdrawals: Int {
        state.withLock { $0 }
    }

    func openFeeSelector() {}
    func openURL(_ url: URL) {}
    func openMail(with dataCollector: EmailDataCollector, recipient: String) {}
    func closeWithdrawal() {}

    func withdrawalDidSend() {
        state.withLock { $0 += 1 }
    }
}
