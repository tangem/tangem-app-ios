//
//  LendingDepositConfirmViewModelTests.swift
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

@Suite("Lending deposit confirm", .timeLimit(.minutes(1)))
@MainActor
final class LendingDepositConfirmViewModelTests: LeakTrackingTestSuite {
    private static let blockchain = Blockchain.ethereum(testnet: false)
    private static let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
    private static let module = "0x1111111111111111111111111111111111111111"
    private static let callData = Data([0x01])

    @Test("Deposit sends the amount to the module with the deposit call and reports the deposit as sent")
    func deposit() async throws {
        let (sut, model, recorder, router) = makeSUT()
        await transactionBuilt(model)

        sut.handle(.deposit)
        await sut.depositTask?.value

        let transaction = try #require(recorder.dispatchedTransactions.first)
        #expect(recorder.dispatchedTransactions.count == 1)
        #expect(transaction.destinationAddress == Self.module)
        #expect(transaction.amount.value == Decimal(string: "0.5"))
        #expect((transaction.params as? EthereumTransactionParams)?.data == Self.callData)
        #expect(router.sentDeposits == 1)
        #expect(sut.alert == nil)
    }

    @Test("A declined card tap leaves the screen as it was, with no pop-up")
    func declinedCardTap() async {
        let (sut, model, recorder, router) = makeSUT(dispatchError: TransactionDispatcherResult.Error.userCancelled)
        await transactionBuilt(model)

        sut.handle(.deposit)
        await sut.depositTask?.value

        #expect(recorder.dispatchedTransactions.count == 1)
        #expect(router.sentDeposits == 0)
        #expect(sut.alert == nil)
    }

    @Test("A deposit that fails to send shows the error pop-up instead of reporting it sent")
    func failedDeposit() async {
        let (sut, model, _, router) = makeSUT(dispatchError: Self.sendError())
        await transactionBuilt(model)

        sut.handle(.deposit)
        await sut.depositTask?.value

        #expect(router.sentDeposits == 0)
        #expect(sut.alert != nil)
    }

    @Test("A fee that went up since it was shown stops the deposit and tells the user")
    func higherFee() async {
        let (sut, model, recorder, router) = makeSUT(relevance: InformationRelevanceServiceStub(isActual: false, updateResult: .feeWasIncreased))
        await transactionBuilt(model)

        sut.handle(.deposit)
        await sut.depositTask?.value

        #expect(recorder.dispatchedTransactions.isEmpty)
        #expect(router.sentDeposits == 0)
        #expect(sut.alert != nil)
    }

    @Test("Deposit turns on once the transaction for the amount is built")
    func depositEnabledWhenReady() async {
        let (sut, model, _, _) = makeSUT()

        await transactionBuilt(model)

        await Task.yield()
        let isDepositEnabled = sut.state.isDepositEnabled
        #expect(isDepositEnabled)
    }

    @Test("Deposit stays off while the network fee would have to come out of the amount")
    func depositOffWhenFeeIncluded() async {
        let (sut, model, _, _) = makeSUT(amountLeavesNoRoomForFee: true)

        await transactionBuilt(model)

        await Task.yield()
        let isDepositEnabled = sut.state.isDepositEnabled
        #expect(!isDepositEnabled)
    }

    @Test("Deposit turns off when the amount is cleared, even with the earlier transaction still built")
    func depositOffWithoutAmount() async {
        let (sut, model, _, _) = makeSUT()
        await transactionBuilt(model)

        model.sourceAmountDidChanged(amount: nil)

        await Task.yield()
        let isDepositEnabled = sut.state.isDepositEnabled
        #expect(!isDepositEnabled)
    }

    @Test("A second tap on Deposit while the deposit is being sent is ignored, so only one deposit goes out")
    func secondTapWhileSendingIsIgnored() async {
        let entered = TestGate()
        let release = TestGate()
        let (sut, model, recorder, router) = makeSUT(dispatchEntered: entered, dispatchRelease: release)
        await transactionBuilt(model)

        sut.handle(.deposit)
        await entered.wait()
        sut.handle(.deposit)
        release.open()
        await sut.depositTask?.value

        #expect(recorder.dispatchedTransactions.count == 1)
        #expect(router.sentDeposits == 1)
    }

    @Test("A legal link opens before the deposit and is ignored while the deposit is sending")
    func legalLinksIgnoredWhileSending() async throws {
        let entered = TestGate()
        let release = TestGate()
        let (sut, model, _, router) = makeSUT(dispatchEntered: entered, dispatchRelease: release)
        await transactionBuilt(model)
        let url = try #require(URL(string: "https://aave.com/terms-of-service"))

        sut.handle(.openURL(url))
        sut.handle(.deposit)
        await entered.wait()
        await Task.yield()
        sut.handle(.openURL(url))
        release.open()
        await sut.depositTask?.value

        #expect(router.openedURLs == [url])
    }

    @Test("A tap on the failed fee row estimates the fee again")
    func retryFee() async {
        let feeManager = TokenFeeProvidersManagerMock(
            feeProvider: ControllableTokenFeeProviderStub(
                feeTokenItem: Self.tokenItem,
                selectedTokenFee: TokenFee(option: .market, tokenItem: Self.tokenItem, value: .failure(NSError(domain: "fee", code: 1)))
            )
        )
        let (sut, model, _, _) = makeSUT(feeManager: feeManager)
        let callsBefore = feeManager.updateFeesCalls

        sut.handle(.retryFee)
        await model.feeUpdateTask?.value

        #expect(feeManager.updateFeesCalls > callsBefore)
    }

    @Test("The screen projects the yearly earnings of the amount")
    func projection() async {
        let (sut, model, _, _) = makeSUT()

        await transactionBuilt(model)

        await Task.yield()
        let projectedEarnings = sut.state.projectedEarnings
        #expect(projectedEarnings == "~$37/year")
    }
}

// MARK: - Helpers

private extension LendingDepositConfirmViewModelTests {
    static func sendError() -> TransactionDispatcherResult.Error {
        let transaction = BSDKTransaction(
            amount: Amount(with: blockchain, type: .coin, value: Decimal(5) / 10),
            fee: Fee(Amount(with: blockchain, type: .coin, value: Decimal(1) / 1000)),
            sourceAddress: "source",
            destinationAddress: module,
            changeAddress: "source"
        )

        return .sendTxError(transaction: .transfer(transaction), error: SendTxError(error: DepositErrorStub()))
    }

    func makeSUT(
        dispatchError: Error? = nil,
        relevance: InformationRelevanceService = InformationRelevanceServiceStub(),
        amountLeavesNoRoomForFee: Bool = false,
        dispatchEntered: TestGate? = nil,
        dispatchRelease: TestGate? = nil,
        feeManager: TokenFeeProvidersManagerMock? = nil
    ) -> (LendingDepositConfirmViewModel, TransferModel, TransactionRecorder, LendingDepositConfirmRouterSpy) {
        let recorder = TransactionRecorder()
        let fee = TokenFee(
            option: .market,
            tokenItem: Self.tokenItem,
            value: .success(Fee(Amount(with: Self.blockchain, type: .coin, value: Decimal(1) / 1000)))
        )
        let token = SendTransferableTokenStub(
            blockchain: Self.blockchain,
            transactionValidator: SendTransactionValidatorStub(
                validateError: amountLeavesNoRoomForFee ? ValidationError.totalExceedsBalance : nil
            ),
            transactionCreator: BuildingTransactionCreatorStub(),
            tokenFeeProvidersManager: feeManager ?? TokenFeeProvidersManagerMock(
                feeProvider: ControllableTokenFeeProviderStub(feeTokenItem: Self.tokenItem, selectedTokenFee: fee)
            ),
            balance: 2,
            transactionDispatcherProvider: RecordingTransactionDispatcherProvider(
                recorder: recorder,
                error: dispatchError,
                entered: dispatchEntered,
                release: dispatchRelease
            )
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
                contractCallData: Self.callData
            )
        )
        model.informationRelevanceService = relevance
        model.sourceAmountDidChanged(amount: SendAmount(type: .typical(crypto: Decimal(string: "0.5"), fiat: 800)))

        let router = LendingDepositConfirmRouterSpy()
        let sut = LendingDepositConfirmViewModel(
            transferModel: model,
            sourceToken: token,
            projection: LendingDepositProjection(
                currentApy: Decimal(55) / 1000,
                performanceFee: Decimal(15) / 100,
                currencyCode: "USD",
                locale: Locale(identifier: "en_US")
            ),
            mailDataBuilder: CommonSendMailDataBuilder(baseDataInput: model, sourceTokenInput: model),
            coordinator: router
        )

        return (trackForMemoryLeaks(sut), trackForMemoryLeaks(model), recorder, router)
    }

    func transactionBuilt(_ model: TransferModel) async {
        _ = await model.bsdkTransactionResultPublisher.values.first { result in
            (try? result?.get()) != nil
        }
    }
}

// MARK: - Stubs

private struct DepositErrorStub: UniversalError {
    var errorCode: Int { 1 }
}

private final class LendingDepositConfirmRouterSpy: LendingDepositConfirmRoutable {
    private let state = OSAllocatedUnfairLock(initialState: 0)
    private let urls = OSAllocatedUnfairLock(initialState: [URL]())

    var sentDeposits: Int {
        state.withLock { $0 }
    }

    var openedURLs: [URL] {
        urls.withLock { $0 }
    }

    func openFeeSelector() {}

    func openURL(_ url: URL) {
        urls.withLock { $0.append(url) }
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {}
    func closeDeposit() {}

    func depositDidSend() {
        state.withLock { $0 += 1 }
    }
}
