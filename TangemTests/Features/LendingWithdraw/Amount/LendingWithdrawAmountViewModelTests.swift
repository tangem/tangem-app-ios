//
//  LendingWithdrawAmountViewModelTests.swift
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

@Suite("Lending withdrawal amount", .timeLimit(.minutes(1)))
@MainActor
final class LendingWithdrawAmountViewModelTests: LeakTrackingTestSuite {
    private static let blockchain = Blockchain.ethereum(testnet: false)
    private static let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
    private static let module = "0x1111111111111111111111111111111111111111"
    private static let position = Decimal(2)

    @Test("A tap on the failed fee row estimates the fee again")
    func retryFee() {
        let (model, token, manager) = makeModel()
        let sut = makeAmount(model: model, token: token)

        sut.handle(.retryFee)

        #expect(manager.updateFeesCalls == 1)
    }

    @Test("Without enough ETH for the network fee the amount field says so")
    func notEnoughForFee() async {
        let (model, token, _) = makeModel(walletBalance: Decimal(1) / 10000)
        let sut = makeAmount(model: model, token: token)

        let info = await sut.amountField.$bottomInfoText.values.first { $0 != nil }

        #expect(info == .error(LendingWithdrawText.notEnough("ETH")))
    }

    @Test("Max fills in everything available to withdraw")
    func maxFillsAvailable() async {
        let (model, token, _) = makeModel(liquidity: .success(Decimal(15) / 10))
        await model.loadAvailableToWithdraw()
        let sut = makeAmount(model: model, token: token)

        sut.handle(.share(100))

        let amount = await MainActor.run { model.sourceAmount.value?.crypto }
        #expect(amount == Decimal(string: "1.5"))
    }

    @Test("A new amount keeps Withdraw off until the fee for that amount arrives")
    func newAmountWaitsForItsFee() async {
        let (model, token, manager) = makeModel()
        let sut = makeAmount(model: model, token: token)
        sut.handle(.share(50))
        _ = await sut.$state.values.first { $0.isSubmitEnabled }

        let feeUpdate = TestGate()
        manager.updateFeesGate = feeUpdate
        sut.handle(.share(100))

        let disabled = await sut.$state.values.first { !$0.isSubmitEnabled }
        #expect(disabled != nil)

        feeUpdate.open()

        let enabled = await sut.$state.values.first { $0.isSubmitEnabled }
        #expect(enabled != nil)
    }

    @Test("An amount entered before the Aave liquidity loads turns Withdraw off once the liquidity is below it")
    func liquidityBelowEnteredAmount() async {
        let (model, token, _) = makeModel(liquidity: .success(Decimal(15) / 10))
        let sut = makeAmount(model: model, token: token)
        sut.handle(.share(100))
        _ = await sut.$state.values.first { $0.isSubmitEnabled }

        await model.loadAvailableToWithdraw()

        let isWithdrawEnabled = await sut.$state.values.first { !$0.isSubmitEnabled }?.isSubmitEnabled
        #expect(isWithdrawEnabled == false)
    }
}

// MARK: - Helpers

private extension LendingWithdrawAmountViewModelTests {
    func amount(_ value: String) -> SendAmount {
        SendAmount(type: .typical(crypto: Decimal(string: value), fiat: nil))
    }

    func makeToken(
        walletBalance: Decimal,
        manager: TokenFeeProvidersManagerMock,
        dispatchError: Error? = nil
    ) -> SendTransferableTokenStub {
        SendTransferableTokenStub(
            blockchain: Self.blockchain,
            transactionCreator: BuildingTransactionCreatorStub(),
            tokenFeeProvidersManager: manager,
            balance: walletBalance,
            transactionDispatcherProvider: RecordingTransactionDispatcherProvider(recorder: TransactionRecorder(), error: dispatchError)
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
        dispatchError: Error? = nil
    ) -> (LendingWithdrawModel, SendTransferableTokenStub, TokenFeeProvidersManagerMock) {
        let manager = makeFeeManager()
        let token = makeToken(walletBalance: walletBalance, manager: manager, dispatchError: dispatchError)
        let model = LendingWithdrawModel(
            sourceToken: token,
            yieldModule: Self.module,
            upgradeImplementation: nil,
            positionBalance: Self.position,
            liquidityProvider: liquidity.map(LendingLiquidityProviderStub.init(result:))
        )

        return (trackForMemoryLeaks(model), token, manager)
    }

    func makeAmount(model: LendingWithdrawModel, token: SendTransferableTokenStub) -> LendingWithdrawAmountViewModel {
        trackForMemoryLeaks(LendingWithdrawAmountViewModel(model: model, sourceToken: token, router: nil))
    }
}
