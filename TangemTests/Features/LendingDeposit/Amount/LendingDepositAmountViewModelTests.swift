//
//  LendingDepositAmountViewModelTests.swift
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

@Suite("Lending deposit amount", .timeLimit(.minutes(1)))
@MainActor
final class LendingDepositAmountViewModelTests: LeakTrackingTestSuite {
    private static let blockchain = Blockchain.ethereum(testnet: false)
    private static let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
    private static let module = "0x1111111111111111111111111111111111111111"

    private var feeProvidersManager: TokenFeeProvidersManagerMock?

    @Test(
        "A share chip deposits that share of the balance left after the network fee",
        arguments: zip([25, 50, 75, 100], ["0.49975", "0.9995", "1.49925", "1.999"])
    )
    func shareChip(percent: Int, deposit: String) async throws {
        let (sut, model, _) = try makeSUT(balance: "2", fee: "0.001")

        sut.handle(.share(percent))

        await transactionBuilt(model, amount: deposit)
        #expect(model.sourceAmount.value?.crypto == Decimal(string: deposit))
    }

    @Test("A share finer than a wei is rounded down to whole wei")
    func shareFinerThanWei() async throws {
        let (sut, model, _) = try makeSUT(balance: "0.000000000000000003", fee: "0")

        sut.handle(.share(50))

        await transactionBuilt(model, amount: "0.000000000000000001")
        #expect(model.sourceAmount.value?.crypto == Decimal(string: "0.000000000000000001"))
    }

    @Test("When the network fee is above the balance, the whole balance leaves nothing to deposit")
    func feeAboveBalance() throws {
        let (sut, model, _) = try makeSUT(balance: "0.0005", fee: "0.001")

        sut.handle(.share(100))

        #expect(model.sourceAmount.value == nil)
        #expect(sut.amountField.cryptoTextFieldViewModel.value == 0)
    }

    @Test("When the network fee is above the balance, the amount line says there's not enough ETH before anything is typed")
    func feeAboveBalanceShowsNotEnough() async throws {
        let (sut, _, _) = try makeSUT(balance: "0.0005", fee: "0.001")

        let info = await shownBottomInfo(sut)

        #expect(info == .error("Not enough ETH"))
    }

    @Test("An amount that doesn't fit next to the network fee says there's not enough ETH")
    func amountAboveMaxShowsNotEnough() async throws {
        let (sut, model, _) = try makeSUT(balance: "2", fee: "0.001")
        await feeShown(sut)

        sut.amountField.onValueChanged?(Decimal(string: "1.9995"))

        let info = await shownBottomInfo(sut)
        #expect(info == .error("Not enough ETH"))
        await transactionBuilt(model, amount: "1.9995")
    }

    @Test("An amount that fits next to the network fee shows no error")
    func amountWithinMaxShowsNoError() async throws {
        let (sut, model, _) = try makeSUT(balance: "2", fee: "0.001")
        sut.handle(.share(100))
        await transactionBuilt(model, amount: "1.999")

        let info = await MainActor.run { sut.amountField.bottomInfoText }
        #expect(info == nil)
    }

    @Test("A new fee estimate that no longer fits next to the amount brings the amount down to the new maximum")
    func newFeeCapsAmount() async throws {
        let (sut, model, feeProvider) = try makeSUT(balance: "2", fee: "0.001")
        sut.handle(.share(100))
        await transactionBuilt(model, amount: "1.999")

        feeProvider.set(selectedTokenFee: try Self.tokenFee("0.002"))

        await transactionBuilt(model, amount: "1.998")
        let shownAmount = await MainActor.run { sut.amountField.cryptoTextFieldViewModel.value }
        #expect(shownAmount == Decimal(string: "1.998"))
    }

    @Test("Max during a fee re-estimate still leaves room for the last estimated fee")
    func maxWhileFeeReloads() async throws {
        let (sut, model, feeProvider) = try makeSUT(balance: "2", fee: "0.001")
        await feeShown(sut)
        feeProvider.set(selectedTokenFee: TokenFee(option: .market, tokenItem: Self.tokenItem, value: .loading))

        sut.handle(.share(100))

        #expect(sut.amountField.cryptoTextFieldViewModel.value == Decimal(string: "1.999"))
        await buildFinished(model)
    }

    @Test("Deposit turns off when the amount is cleared after a valid one")
    func clearedAmountDisablesDeposit() async throws {
        let (sut, model, _) = try makeSUT(balance: "2", fee: "0.001")
        sut.handle(.share(50))
        await transactionBuilt(model, amount: "0.9995")
        await depositEnabled(sut)

        sut.amountField.onValueChanged?(nil)

        let isSubmitEnabled = await MainActor.run { sut.state.isSubmitEnabled }
        #expect(!isSubmitEnabled)
    }

    @Test("Deposit stays off after the amount changes until the network fee for the new amount arrives")
    func newAmountWaitsForItsFee() async throws {
        let (sut, model, _) = try makeSUT(balance: "2", fee: "0.001")
        sut.handle(.share(50))
        await transactionBuilt(model, amount: "0.9995")
        await depositEnabled(sut)

        let feeUpdate = TestGate()
        feeProvidersManager?.updateFeesGate = feeUpdate

        sut.amountField.onValueChanged?(1)
        await transactionBuilt(model, amount: "1")

        let isSubmitEnabled = await MainActor.run { sut.state.isSubmitEnabled }
        #expect(!isSubmitEnabled)
        feeUpdate.open()
        await depositEnabled(sut)
    }

    @Test("Deposit turns off when the balance drops below the amount and the network fee")
    func balanceDropDisablesDeposit() async throws {
        let balance = ControllableTokenBalanceProviderStub(balance: 2)
        let (sut, model, _) = try makeSUT(balance: "2", fee: "0.001", balanceProvider: balance)
        sut.handle(.share(50))
        await transactionBuilt(model, amount: "0.9995")
        await depositEnabled(sut)

        balance.set(balance: Decimal(1) / 2)

        let disabled = await sut.$state.values.first { !$0.isSubmitEnabled }
        #expect(disabled != nil)
    }

    @Test("A repeated fee estimate with the same fee leaves the typed amount alone", arguments: ["1.99", "1.9995"])
    func sameFeeKeepsTypedAmount(typed: String) async throws {
        let (sut, model, feeProvider) = try makeSUT(balance: "2", fee: "0.001")
        await feeShown(sut)
        sut.amountField.onValueChanged?(Decimal(string: typed))
        await transactionBuilt(model, amount: typed)

        try await reloadFee(sut, feeProvider, to: "0.001")

        let depositAmount = await MainActor.run { model.sourceAmount.value?.crypto }
        #expect(depositAmount == Decimal(string: typed))
        await buildFinished(model)
    }

    @Test("Max tapped before the first fee estimate fills in the balance minus that fee once it arrives")
    func maxBeforeFirstFee() async throws {
        let (sut, model, feeProvider) = try makeSUT(balance: "2", fee: "0.001", isFeeLoaded: false)
        await MainActor.run {}
        sut.handle(.share(100))

        feeProvider.set(selectedTokenFee: try Self.tokenFee("0.001"))
        await transactionBuilt(model, amount: "1.999")

        let depositAmount = await MainActor.run { model.sourceAmount.value?.crypto }
        #expect(depositAmount == Decimal(string: "1.999"))
    }

    @Test("The first fee estimate leaves an amount typed before it alone, so it says there's not enough ETH as it does when retyped")
    func firstFeeKeepsTypedAmount() async throws {
        let (sut, model, feeProvider) = try makeSUT(balance: "2", fee: "0.001", isFeeLoaded: false)
        await MainActor.run {}
        sut.amountField.onValueChanged?(Decimal(2))

        feeProvider.set(selectedTokenFee: try Self.tokenFee("0.001"))
        await feeShown(sut)

        let depositAmount = await MainActor.run { model.sourceAmount.value?.crypto }
        #expect(depositAmount == 2)
        #expect(await shownBottomInfo(sut) == .error("Not enough ETH"))
        await buildFinished(model)
    }

    @Test("Deposit stays off while the amount leaves no room for the network fee")
    func amountWithoutRoomForFee() async throws {
        let (sut, model, _) = try makeSUT(balance: "2", fee: "0.001", amountLeavesNoRoomForFee: true)
        await MainActor.run {}

        sut.amountField.onValueChanged?(Decimal(string: "1.9995"))

        await transactionBuilt(model, amount: "1.9985")
        let isSubmitEnabled = await MainActor.run { sut.state.isSubmitEnabled }
        #expect(!isSubmitEnabled)
    }

    @Test("A tap on the failed fee row estimates the fee again")
    func retryFee() async throws {
        let (sut, model, _) = try makeSUT(balance: "2", fee: "0.001")
        let manager = try #require(model.tokenFeeProvidersManager as? TokenFeeProvidersManagerMock)

        sut.handle(.retryFee)

        await model.feeUpdateTask?.value
        #expect(manager.updateFeesCalls == 1)
    }
}

// MARK: - Helpers

private extension LendingDepositAmountViewModelTests {
    static func tokenFee(_ value: String) throws -> TokenFee {
        let fee = try #require(Decimal(string: value))

        return TokenFee(
            option: .market,
            tokenItem: tokenItem,
            value: .success(Fee(Amount(with: blockchain, type: .coin, value: fee)))
        )
    }

    func makeSUT(
        balance: String,
        fee: String,
        isFeeLoaded: Bool = true,
        amountLeavesNoRoomForFee: Bool = false,
        balanceProvider: TokenBalanceProvider? = nil
    ) throws -> (LendingDepositAmountViewModel, TransferModel, ControllableTokenFeeProviderStub) {
        let balanceValue = try #require(Decimal(string: balance))
        let initialFee = try isFeeLoaded ? Self.tokenFee(fee) : TokenFee(option: .market, tokenItem: Self.tokenItem, value: .loading)
        let feeProvider = ControllableTokenFeeProviderStub(feeTokenItem: Self.tokenItem, selectedTokenFee: initialFee)
        let feeProvidersManager = TokenFeeProvidersManagerMock(feeProvider: feeProvider)
        self.feeProvidersManager = feeProvidersManager
        let token = SendTransferableTokenStub(
            blockchain: Self.blockchain,
            transactionValidator: SendTransactionValidatorStub(
                validateError: amountLeavesNoRoomForFee ? ValidationError.totalExceedsBalance : nil
            ),
            transactionCreator: BuildingTransactionCreatorStub(),
            tokenFeeProvidersManager: feeProvidersManager,
            balance: balanceValue,
            balanceProvider: balanceProvider
        )

        let model = TransferModel(
            userWalletId: UserWalletId(value: Data([0x01])),
            userToken: token,
            transactionSigner: TangemSignerStub(),
            feeIncludedCalculator: CommonFeeIncludedCalculator(validator: token.transactionValidator),
            analyticsLogger: SendManagementModelAnalyticsLoggerStub(),
            sendAlertBuilder: CommonSendAlertBuilder(),
            predefinedValues: TransferModel.PredefinedValues(
                destination: SendDestination(value: .plain(Self.module), source: .textField),
                contractCallData: Data([0x01])
            )
        )

        let sut = LendingDepositAmountViewModel(transferModel: model, sourceToken: token, router: nil)

        return (trackForMemoryLeaks(sut), trackForMemoryLeaks(model), feeProvider)
    }

    func feeShown(_ sut: LendingDepositAmountViewModel) async {
        _ = await sut.$state.values.first { state in
            if case .loaded = state.fee { true } else { false }
        }
    }

    func reloadFee(_ sut: LendingDepositAmountViewModel, _ feeProvider: ControllableTokenFeeProviderStub, to fee: String) async throws {
        feeProvider.set(selectedTokenFee: TokenFee(option: .market, tokenItem: Self.tokenItem, value: .loading))
        _ = await sut.$state.values.first { state in
            if case .loading = state.fee { true } else { false }
        }

        feeProvider.set(selectedTokenFee: try Self.tokenFee(fee))
        await feeShown(sut)
    }

    func shownBottomInfo(_ sut: LendingDepositAmountViewModel) async -> SendAmountViewModel.BottomInfoTextType? {
        await sut.amountField.$bottomInfoText.values.first { $0 != nil } ?? nil
    }

    func depositEnabled(_ sut: LendingDepositAmountViewModel) async {
        _ = await sut.$state.values.first { $0.isSubmitEnabled }
    }

    func buildFinished(_ model: TransferModel) async {
        await model.transactionBuildTask?.value
    }

    func transactionBuilt(_ model: TransferModel, amount: String) async {
        let expected = Decimal(string: amount)
        _ = await model.bsdkTransactionResultPublisher.values.first { result in
            (try? result?.get())?.amount.value == expected
        }
        await model.transactionBuildTask?.value
    }
}
