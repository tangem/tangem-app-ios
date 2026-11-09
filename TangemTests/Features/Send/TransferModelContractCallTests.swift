//
//  TransferModelContractCallTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemTestKit
@testable import BlockchainSdk
@testable import Tangem

@Suite("TransferModel contract call", .timeLimit(.minutes(1)))
final class TransferModelContractCallTests: LeakTrackingTestSuite {
    private static let blockchain = Blockchain.ethereum(testnet: false)
    private static let contract = "0x1111111111111111111111111111111111111111"
    private static let callData = Data([0x09, 0x21, 0xEC, 0xD4])
    private static let fee = Fee(Amount(with: blockchain, type: .coin, value: Decimal(1) / 1000))
    private static let coin = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
    private static let usdt = TokenItem.accountToken(
        symbol: "USDT",
        contract: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        blockchain: blockchain
    )

    @Test("Without a contract call the fee is estimated for a plain transfer")
    func plainTransferFeeInput() async {
        let (sut, feeManager, _) = makeSUT(contractCall: false, amount: "1")

        sut.updateFees()

        await sut.feeUpdateTask?.value
        await transactionBuilt(sut)
        #expect(feeManager.updateInputCalls == [.common(amount: 1, destination: Self.contract)])
    }

    @Test(
        "A contract call's fee is estimated for the call, valued at no more than half the balance rounded down to whole wei",
        arguments: [("2", "0.5", "0.5"), ("2", "1.8", "1"), ("2.000000000000000001", "1.9", "1")]
    )
    func contractCallFeeInput(balance: String, amount: String, estimatedValue: String) async throws {
        let (sut, feeManager, _) = try makeSUT(amount: amount, balance: #require(Decimal(string: balance)))
        let estimatedAmount = try Amount(with: Self.blockchain, type: .coin, value: #require(Decimal(string: estimatedValue)))

        sut.updateFees()

        await sut.feeUpdateTask?.value
        await transactionBuilt(sut)
        #expect(feeManager.updateInputCalls == [
            .dex(.ethereum(
                amount: estimatedAmount,
                destination: Self.contract,
                txData: Self.callData,
                otherNativeFee: nil,
                gasLimitIncreasePercent: EthereumFeeParametersConstants.yieldModuleGasLimitIncreasePercent
            )),
        ])
    }

    @Test("A contract call is sent to the contract with its calldata and the amount as its value")
    func sendsCall() async throws {
        let (sut, _, recorder) = makeSUT(amount: "0.5")

        _ = try await sut.performAction()

        let sent = try #require(recorder.dispatchedTransactions.last)
        #expect(sent.destinationAddress == Self.contract)
        #expect(sent.amount.value == Decimal(5) / 10)
        #expect((sent.params as? EthereumTransactionParams)?.data == Self.callData)
    }

    @Test("A contract call is never sent from a token, since only the network coin can be the call's value")
    func tokenContractCallIsNotSent() async {
        let (sut, _, recorder) = makeSUT(tokenItem: Self.usdt, amount: "0.5")

        await #expect(throws: (any Error).self) {
            try await sut.performAction()
        }
        #expect(recorder.dispatchedTransactions.isEmpty)
    }

    @Test(
        "A contract call is never sent without at least one wei as its value, so the user can't pay gas for depositing nothing",
        arguments: ["0", "0.0000000000000000001"]
    )
    func contractCallWithoutWholeWeiIsNotSent(amount: String) async {
        let (sut, _, recorder) = makeSUT(amount: amount)

        await #expect(throws: (any Error).self) {
            try await sut.performAction()
        }
        #expect(recorder.dispatchedTransactions.isEmpty)
    }
}

// MARK: - Helpers

private extension TransferModelContractCallTests {
    func transactionBuilt(_ sut: TransferModel) async {
        _ = await sut.bsdkTransactionResultPublisher.values.first { $0 != nil }
        await sut.transactionBuildTask?.value
    }

    func makeSUT(
        tokenItem: TokenItem? = nil,
        contractCall: Bool = true,
        amount: String? = nil,
        balance: Decimal = 2
    ) -> (TransferModel, TokenFeeProvidersManagerMock, TransactionRecorder) {
        let feeProvider = ControllableTokenFeeProviderStub(
            feeTokenItem: Self.coin,
            selectedTokenFee: TokenFee(option: .market, tokenItem: Self.coin, value: .success(Self.fee))
        )
        let feeManager = TokenFeeProvidersManagerMock(feeProvider: feeProvider)
        let recorder = TransactionRecorder()

        let sut = TransferModel(
            userWalletId: UserWalletId(value: Data([0x01])),
            userToken: ContractCallTokenStub(
                tokenItem: tokenItem ?? Self.coin,
                balance: balance,
                tokenFeeProvidersManager: feeManager,
                recorder: recorder
            ),
            transactionSigner: TangemSignerStub(),
            feeIncludedCalculator: FeeIncludedCalculatorStub(),
            analyticsLogger: SendManagementModelAnalyticsLoggerStub(),
            sendAlertBuilder: CommonSendAlertBuilder(),
            predefinedValues: TransferModel.PredefinedValues(
                destination: SendDestination(value: .plain(Self.contract), source: .textField),
                amount: amount.flatMap { Decimal(string: $0) }.map { SendAmount(type: .typical(crypto: $0, fiat: nil)) },
                contractCallData: contractCall ? Self.callData : nil
            )
        )
        sut.informationRelevanceService = InformationRelevanceServiceStub()

        return (trackForMemoryLeaks(sut), feeManager, recorder)
    }
}

// MARK: - Stubs

private final class ContractCallTokenStub: SendSourceTokenStub, SendTransferableToken {
    let transactionValidator: SendTransactionValidator = SendTransactionValidatorStub()
    let transactionCreator: SendTransactionCreator = BuildingTransactionCreatorStub()
    let tokenFeeProvidersManager: TokenFeeProvidersManager

    private let balance: Decimal
    private let recorder: TransactionRecorder

    init(tokenItem: TokenItem, balance: Decimal, tokenFeeProvidersManager: TokenFeeProvidersManager, recorder: TransactionRecorder) {
        self.balance = balance
        self.tokenFeeProvidersManager = tokenFeeProvidersManager
        self.recorder = recorder
        super.init(tokenItem: tokenItem)
    }

    override var availableBalanceProvider: TokenBalanceProvider {
        LoadedBalanceProviderStub(balance: balance)
    }

    override var transactionDispatcherProvider: any TransactionDispatcherProvider {
        RecordingTransactionDispatcherProvider(recorder: recorder)
    }
}

private struct LoadedBalanceProviderStub: TokenBalanceProvider {
    let balance: Decimal

    var balanceType: TokenBalanceType { .loaded(balance) }
    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> { .just(output: balanceType) }
    var formattedBalanceType: FormattedTokenBalanceType { .loading(.empty("-")) }
    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { .just(output: formattedBalanceType) }
}

private struct BuildingTransactionCreatorStub: SendTransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Fee,
        destinationAddress: String,
        params: TransactionParams?
    ) async throws -> BSDKTransaction {
        Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: "",
            destinationAddress: destinationAddress,
            changeAddress: "",
            contractAddress: nil,
            params: params
        )
    }
}
