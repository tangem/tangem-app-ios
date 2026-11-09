//
//  TransferModelSentTransactionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

private enum TestData {
    static let sourceAddress = "TJRabPrwbZy45sbavfcjinPJC18kjpRTv8"
    static let destinationAddress = "TLsV52sRDL79HXGGm9yzwKibb6BeruhUzy"
}

@Suite("TransferModel after the transaction is sent", .timeLimit(.minutes(1)))
struct TransferModelSentTransactionTests {
    @Test("A fee that fails once the transaction is sent leaves the sent transaction in place")
    func failingFeeAfterSendKeepsSentTransaction() async throws {
        let (sut, feeProvider) = makeSUT()
        let sentTransaction = try await awaitBuiltTransaction(sut)

        _ = try await sut.performAction()
        #expect(feeProvider.releasedSelectedFeeSubscriptions == 1)

        feeProvider.set(selectedTokenFee: makeTokenFee(
            feeTokenItem: feeProvider.feeTokenItem,
            value: .failure(TokenFeeProviderError.notEnoughGaslessFeeBalance(feeCurrencyBalance: 0))
        ))

        let currentTransaction = try await currentTransaction(sut)
        #expect(currentTransaction.fee.amount == sentTransaction.fee.amount)
    }
}

// MARK: - Helpers

private extension TransferModelSentTransactionTests {
    func makeSUT() -> (TransferModel, TokenFeeProviderSpy) {
        let blockchain = Blockchain.tron(testnet: false)
        let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
        let fee = Fee(Amount(with: blockchain, type: .coin, value: 1))
        let feeProvider = TokenFeeProviderSpy(
            stub: ControllableTokenFeeProviderStub(
                feeTokenItem: tokenItem,
                selectedTokenFee: makeTokenFee(feeTokenItem: tokenItem, value: .success(fee))
            )
        )
        let sourceToken = SendTransferableTokenStub(
            blockchain: blockchain,
            transactionCreator: TransactionBuildingCreatorStub(sourceAddress: TestData.sourceAddress),
            tokenFeeProvidersManager: TokenFeeProvidersManagerMock(feeProvider: feeProvider),
            transactionDispatcherProvider: RecordingTransactionDispatcherProvider(recorder: TransactionRecorder())
        )

        let sut = TransferModel(
            userWalletId: UserWalletId(value: Data([0x01])),
            userToken: sourceToken,
            transactionSigner: TangemSignerStub(),
            feeIncludedCalculator: FeeIncludedCalculatorStub(),
            analyticsLogger: SendManagementModelAnalyticsLoggerStub(),
            sendAlertBuilder: CommonSendAlertBuilder(),
            predefinedValues: .init(
                destination: SendDestination(value: .plain(TestData.destinationAddress), source: .pasteButton),
                amount: SendAmount(type: .typical(crypto: 10, fiat: nil))
            )
        )
        sut.informationRelevanceService = InformationRelevanceServiceStub()

        return (sut, feeProvider)
    }

    func makeTokenFee(feeTokenItem: TokenItem, value: LoadingResult<Fee, any Error>) -> TokenFee {
        TokenFee(option: .market, tokenItem: feeTokenItem, value: value)
    }

    func awaitBuiltTransaction(_ model: TransferModel) async throws -> BSDKTransaction {
        try await model.bsdkTransactionResultPublisher
            .compactMap { result -> BSDKTransaction? in
                guard case .success(let transaction) = result else {
                    return nil
                }

                return transaction
            }
            .first()
            .async()
    }

    func currentTransaction(_ model: TransferModel) async throws -> BSDKTransaction {
        let result = try await model.bsdkTransactionResultPublisher.first().async()
        return try #require(result).get()
    }
}

// MARK: - Stubs

private final class TokenFeeProviderSpy: TokenFeeProvider {
    private let stub: ControllableTokenFeeProviderStub
    private let releasedSubscriptions = OSAllocatedUnfairLock(initialState: 0)

    init(stub: ControllableTokenFeeProviderStub) {
        self.stub = stub
    }

    var releasedSelectedFeeSubscriptions: Int {
        releasedSubscriptions.withLock { $0 }
    }

    func set(selectedTokenFee fee: TokenFee) {
        stub.set(selectedTokenFee: fee)
    }

    var feeTokenItem: TokenItem { stub.feeTokenItem }
    var hasMultipleFeeOptions: Bool { stub.hasMultipleFeeOptions }
    var balanceFeeTokenState: TokenBalanceType { stub.balanceFeeTokenState }
    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> { stub.balanceTypePublisher }
    var formattedFeeTokenBalance: FormattedTokenBalanceType { stub.formattedFeeTokenBalance }
    var state: TokenFeeProviderState { stub.state }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { stub.statePublisher }
    var selectedTokenFee: TokenFee { stub.selectedTokenFee }
    var fees: [TokenFee] { stub.fees }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { stub.feesPublisher }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        stub.selectedTokenFeePublisher
            .handleEvents(receiveCancel: { [releasedSubscriptions] in
                releasedSubscriptions.withLock { $0 += 1 }
            })
            .eraseToAnyPublisher()
    }

    func select(feeOption: FeeOption) {
        stub.select(feeOption: feeOption)
    }

    func setup(input: TokenFeeProviderInputData) {
        stub.setup(input: input)
    }

    func updateFees() -> Task<Void, Never> {
        stub.updateFees()
    }
}

private struct TransactionBuildingCreatorStub: SendTransactionCreator {
    let sourceAddress: String

    func createTransaction(
        amount: Amount,
        fee: Fee,
        destinationAddress: String,
        params: TransactionParams?
    ) async throws -> BSDKTransaction {
        Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: "",
            contractAddress: nil,
            params: params
        )
    }
}
