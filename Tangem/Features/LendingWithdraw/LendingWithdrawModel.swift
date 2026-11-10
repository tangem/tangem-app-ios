//
//  LendingWithdrawModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import TangemFoundation

final class LendingWithdrawModel {
    private let token: SendTransferableToken
    private let yieldModule: String
    private let upgradeImplementation: String?
    private let positionBalance: Decimal
    private let liquidityProvider: YieldModuleLendingLiquidityProvider?
    private let pendingTransactions: AnyPublisher<[PendingTransactionRecord], Never>

    private let _amount = CurrentValueSubject<SendAmount?, Never>(nil)
    private let _availableToWithdraw: CurrentValueSubject<Decimal, Never>
    private let _isWithdrawing = CurrentValueSubject<Bool, Never>(false)
    private let feeRequest = OSAllocatedUnfairLock<FeeRequest?>(initialState: nil)
    private var informationRelevanceService: InformationRelevanceService?

    init(
        sourceToken: SendTransferableToken,
        yieldModule: String,
        upgradeImplementation: String?,
        positionBalance: Decimal,
        availableToWithdraw: Decimal? = nil,
        liquidityProvider: YieldModuleLendingLiquidityProvider?,
        pendingTransactions: AnyPublisher<[PendingTransactionRecord], Never> = .just(output: []),
        informationRelevanceService: InformationRelevanceService? = nil
    ) {
        token = sourceToken
        self.yieldModule = yieldModule
        self.upgradeImplementation = upgradeImplementation
        self.positionBalance = positionBalance
        self.liquidityProvider = liquidityProvider
        self.pendingTransactions = pendingTransactions
        _availableToWithdraw = CurrentValueSubject(availableToWithdraw ?? positionBalance)

        self.informationRelevanceService = informationRelevanceService ?? CommonInformationRelevanceService(input: self, provider: self)
    }

    var availableToWithdraw: Decimal {
        _availableToWithdraw.value
    }

    var availableToWithdrawPublisher: AnyPublisher<Decimal, Never> {
        _availableToWithdraw.eraseToAnyPublisher()
    }

    var isWithdrawingPublisher: AnyPublisher<Bool, Never> {
        _isWithdrawing.eraseToAnyPublisher()
    }

    var isFeeCoveredPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest3(
            token.tokenFeeProvidersManager.selectedTokenFeePublisher,
            token.tokenFeeProvidersManager.selectedFeeTokenUsageAvailabilityPublisher,
            token.availableBalanceProvider.balanceTypePublisher
        )
        .map { tokenFee, availability, balance in
            guard let fee = tokenFee.value.value, availability.allowsFeePayment else {
                return false
            }

            guard fee.amount.type == .coin else {
                return true
            }

            return (balance.value ?? 0) >= fee.amount.value
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    @discardableResult
    func loadAvailableToWithdraw() async -> Decimal? {
        guard liquidityProvider != nil else {
            return nil
        }

        do {
            return try await readAvailableToWithdraw()
        } catch {
            AppLogger.error(error: error)
            _availableToWithdraw.send(positionBalance)
            return nil
        }
    }

    func withdraw() async throws -> TransactionDispatcherResult {
        _isWithdrawing.send(true)
        defer { _isWithdrawing.send(false) }

        try await ensureNoPendingModuleTransaction()
        try await ensureFeeIsActual()

        guard let amount = _amount.value?.crypto else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let available: Decimal
        do {
            available = try await readAvailableToWithdraw()
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error.toUniversalError())
        }

        guard amount <= available else {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: ValidationError.amountExceedsBalance.toUniversalError())
        }

        let data: Data
        do {
            data = try callData(amount: amount)
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error.toUniversalError())
        }

        try await ensureFeeIsEstimated(for: data)

        guard let fee = token.tokenFeeProvidersManager.selectedTokenFee.value.value else {
            throw TransactionDispatcherResult.Error.feeNotFound
        }

        let transaction: BSDKTransaction
        do {
            transaction = try await token.transactionCreator.createTransaction(
                amount: zeroAmount,
                fee: fee,
                destinationAddress: yieldModule,
                params: EthereumTransactionParams(data: data)
            )
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error.toUniversalError())
        }

        try Task.checkCancellation()

        let dispatcher = token.transactionDispatcherProvider.makeTransferTransactionDispatcher()
        return try await dispatcher.send(transaction: .transfer(transaction))
    }
}

// MARK: - Private

private extension LendingWithdrawModel {
    var zeroAmount: Amount {
        Amount(with: token.tokenItem.blockchain, type: .coin, value: 0)
    }

    func withdrawal(amount: Decimal) -> YieldLendingTransactionProvider.WithdrawalAmount {
        amount >= positionBalance ? .all : .partial(amount)
    }

    func callData(amount: Decimal) throws -> Data {
        try YieldLendingTransactionProvider.withdrawCallData(
            withdrawal(amount: amount),
            blockchain: token.tokenItem.blockchain,
            upgradeImplementation: upgradeImplementation
        )
    }

    func readAvailableToWithdraw() async throws -> Decimal {
        guard let liquidityProvider else {
            return positionBalance
        }

        let available = try await liquidityProvider.availableToWithdraw(nativePosition: positionBalance)
        _availableToWithdraw.send(available)
        return available
    }

    func ensureNoPendingModuleTransaction() async throws {
        let pending = try await pendingTransactions.async()

        guard !pending.contains(where: { !$0.isIncoming && $0.destination.caseInsensitiveEquals(to: yieldModule) }) else {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: PendingModuleTransactionError().toUniversalError())
        }
    }

    func ensureFeeIsActual() async throws {
        guard let informationRelevanceService, !informationRelevanceService.isActual else {
            return
        }

        let result = try await informationRelevanceService.updateInformation().mapToResult().async()
        switch result {
        case .failure:
            throw TransactionDispatcherResult.Error.informationRelevanceServiceError
        case .success(.feeWasIncreased):
            throw TransactionDispatcherResult.Error.informationRelevanceServiceFeeWasIncreased
        case .success(.ok):
            return
        }
    }

    func ensureFeeIsEstimated(for data: Data) async throws {
        guard let request = feeRequest.withLock({ $0 }), request.callData == data else {
            throw TransactionDispatcherResult.Error.informationRelevanceServiceError
        }

        await request.task.value
        try Task.checkCancellation()

        guard feeRequest.withLock({ $0?.task }) == request.task else {
            throw TransactionDispatcherResult.Error.informationRelevanceServiceError
        }
    }
}

// MARK: - FeeRequest

private extension LendingWithdrawModel {
    struct FeeRequest {
        let callData: Data
        let task: Task<Void, Never>
    }
}

// MARK: - PendingModuleTransactionError

extension LendingWithdrawModel {
    struct PendingModuleTransactionError: LocalizedError {
        // [REDACTED_TODO_COMMENT]
        var errorDescription: String? {
            "Your previous Aave transaction is still processing. Try again once it is confirmed."
        }
    }
}

// MARK: - SendFeeUpdater

extension LendingWithdrawModel: SendFeeUpdater {
    func updateFees() {
        let amount = _amount.value?.crypto ?? availableToWithdraw

        guard let data = try? callData(amount: amount) else {
            return
        }

        let manager = token.tokenFeeProvidersManager
        let input = TokenFeeProviderInputData.dex(.ethereum(
            amount: zeroAmount,
            destination: yieldModule,
            txData: data,
            otherNativeFee: nil,
            gasLimitIncreasePercent: EthereumFeeParametersConstants.yieldModuleGasLimitIncreasePercent
        ))

        feeRequest.withLock { request in
            manager.update(input: input)
            request = FeeRequest(callData: data, task: manager.updateFees())
        }
    }
}

// MARK: - SendFeeInput

extension LendingWithdrawModel: SendFeeInput {
    var selectedFee: TokenFee? {
        token.tokenFeeProvidersManager.selectedTokenFee
    }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> {
        token.tokenFeeProvidersManager.selectedTokenFeePublisher
    }

    var isSelectedFeeActual: Bool {
        selectedFee?.value.value != nil
    }

    var supportFeeSelection: Bool {
        token.tokenFeeProvidersManager.supportFeeSelection
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        token.tokenFeeProvidersManager.supportFeeSelectionPublisher
    }
}

// MARK: - SendSourceTokenInput

extension LendingWithdrawModel: SendSourceTokenInput {
    var sourceToken: LoadingResult<SendSourceToken, any Error> {
        .success(token as SendSourceToken)
    }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        Just(sourceToken).eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenAmountInput

extension LendingWithdrawModel: SendSourceTokenAmountInput {
    var sourceAmount: LoadingResult<SendAmount, any Error> {
        _amount.value.map { .success($0) } ?? .failure(SendAmountError.noAmount)
    }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        _amount
            .map { $0.map { .success($0) } ?? .failure(SendAmountError.noAmount) }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenAmountOutput

extension LendingWithdrawModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - SendBaseDataBuilderInput

extension LendingWithdrawModel: SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? {
        _amount.value?.crypto.map { Amount(with: token.tokenItem.blockchain, type: .coin, value: $0) }
    }

    var bsdkFee: BSDKFee? {
        selectedFee?.value.value
    }

    var isFeeIncluded: Bool {
        false
    }
}

// MARK: - TokenFeeProvidersManagerProviding

extension LendingWithdrawModel: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: TokenFeeProvidersManager? {
        token.tokenFeeProvidersManager
    }
}

// MARK: - FeeSelectorOutput

extension LendingWithdrawModel: FeeSelectorOutput {
    func userDidFinishSelection(feeProviderID: TokenFeeProviderID, feeOption: FeeOption) {
        token.tokenFeeProvidersManager.update(feeOption: feeOption)
        token.tokenFeeProvidersManager.updateSelectedFeeProvider(feeProviderID: feeProviderID)
    }
}
