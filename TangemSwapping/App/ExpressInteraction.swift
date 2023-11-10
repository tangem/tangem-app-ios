//
//  ExpressInteraction.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping
import BlockchainSdk

extension ExpressInteractor {
    enum ExpressInteractorState {
        case idle

        // After change swappingItems
        case loading(type: SwappingManagerRefreshType)

        // Restrictions
        case permissionRequired(state: PermissionRequiredViewState)
        case hasPendingTransaction
        case notEnoughAmountForSwapping
        case notEnoughAmountForFee

        case readyToSwap(state: ReadyToSwapViewState)

        case requiredRefresh(occurredError: Error)
    }

    struct SwappingItems {
        let source: WalletModel
        let destination: WalletModel?
    }

    struct PermissionRequiredViewState {
        let spender: String
        let toContractAddress: String
        let data: Data
        let fees: [FeeOption: Fee]
    }

    struct ReadyToSwapViewState {
        let data: ExpressTransactionData
        let fees: [FeeOption: Fee]
    }
}

class ExpressInteractor {
    // MARK: - Public

    public let _state = CurrentValueSubject<ExpressInteractorState, Never>(.idle)

    // MARK: - Dependencies

    private let expressManager: ExpressManager
    private let allowanceProvider: AllowanceProvider
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let logger: SwappingLogger

    // MARK: - Private

    // MARK: - Options

    private var sender: ThreadSafeContainer<WalletModel>
    private var destination: ThreadSafeContainer<WalletModel?>

    private(set) var approvePolicy: SwappingApprovePolicy = .unlimited
    private(set) var feeOption: FeeOption = .market

    private var updateStateTask: Task<Void, Error>?

    init(
        sender: WalletModel,
        expressManager: ExpressManager,
        allowanceProvider: AllowanceProvider,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        logger: SwappingLogger
    ) {
        self.sender = .init(sender)
        destination = .init(nil)

        self.expressManager = expressManager
        self.allowanceProvider = allowanceProvider
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.logger = logger

        bind()
    }
}

extension ExpressInteractor {
    func bind() {}
}

// MARK: - Public

extension ExpressInteractor {
    func update(sender wallet: WalletModel) {
        logger.debug("[Swap] \(self) will update sender to \(sender)")

        sender.mutate { $0 = wallet }

        guard let destination = destination.read() else {
            logger.debug("[Swap] \(self) The destination not found")
            return
        }

        let pair = ExpressManagerSwappingPair(source: wallet, destination: destination)
        throwableUpdateTask { interactor in
            let state = try await interactor.expressManager.updatePair(pair: pair)
            try await interactor.updateViewForExpressManagerState(state)
        }
    }

    func update(destination wallet: WalletModel) {
        logger.debug("[Swap] \(self) will update destination to \(wallet)")

        destination.mutate { $0 = wallet }

        let pair = ExpressManagerSwappingPair(source: sender.read(), destination: wallet)
        throwableUpdateTask { interactor in
            let state = try await interactor.expressManager.updatePair(pair: pair)
            try await interactor.updateViewForExpressManagerState(state)
        }
    }

    func update(amount: Decimal?) {
        logger.debug("[Swap] \(self) will update amount to \(amount as Any)")

        throwableUpdateTask { interactor in
            let state = try await interactor.expressManager.updateAmount(amount: amount)
            try await interactor.updateViewForExpressManagerState(state)
        }
    }

    func updateProvider(provider: ExpressProvider) {
        logger.debug("[Swap] \(self) will update provider to \(provider)")

        throwableUpdateTask { interactor in
            let state = try await interactor.expressManager.updateSelectedProvider(provider: provider)
            try await interactor.updateViewForExpressManagerState(state)
        }
    }

    func updateApprovePolicy(policy: SwappingApprovePolicy) {
        approvePolicy = policy

        throwableUpdateTask { interactor in
            try await interactor.approvePolicyDidChange()
        }
    }

    func updateFeeOption(option: FeeOption) {
        feeOption = option

        throwableUpdateTask { interactor in
            try await interactor.approvePolicyDidChange()
        }
    }
}

// MARK: - Refresh

private extension ExpressInteractor {
    func refresh(type: SwappingManagerRefreshType) {
        AppLog.shared.debug("[Swap] did requested for refresh with \(type)")

        guard let amount = expressManager.getAmount(), amount > 0 else {
            updateViewState(.idle)
            return
        }

        AppLog.shared.debug("[Swap] ExpressInteractor start refreshing task")
        updateViewState(.loading(type: type))

        throwableUpdateTask { interactor in
            let state = try await interactor.expressManager.update()
            try await interactor.updateViewForExpressManagerState(state)
        }
    }

    func cancelRefresh() {
        guard updateStateTask != nil else {
            return
        }

        logger.debug("[Swap] ExpressInteraction cancel the refreshing task")

        updateStateTask?.cancel()
        updateStateTask = nil
    }

    func didSendApproveTransaction(swappingTxData: SwappingTransactionData) {
        expressPendingTransactionRepository.didSendApproveTransaction(swappingTxData: swappingTxData)
        refresh(type: .full)

        let permissionType: Analytics.ParameterValue = {
            switch approvePolicy {
            case .specified: return .oneTransactionApprove
            case .unlimited: return .unlimitedApprove
            }
        }()

        Analytics.log(event: .transactionSent, params: [
            .commonSource: Analytics.ParameterValue.transactionSourceApprove.rawValue,
            .feeType: getAnalyticsFeeType()?.rawValue ?? .unknown,
            .token: swappingTxData.sourceCurrency.symbol,
            .blockchain: swappingTxData.sourceBlockchain.name,
            .permissionType: permissionType.rawValue,
        ])
    }

    func didSendSwapTransaction(swappingTxData: SwappingTransactionData) {
        expressPendingTransactionRepository.didSendSwapTransaction(swappingTxData: swappingTxData)
        updateViewState(.idle)

        Analytics.log(event: .transactionSent, params: [
            .commonSource: Analytics.ParameterValue.transactionSourceSwap.rawValue,
            .token: swappingTxData.sourceCurrency.symbol,
            .blockchain: swappingTxData.sourceBlockchain.name,
            .feeType: getAnalyticsFeeType()?.rawValue ?? .unknown,
        ])
    }
}

// MARK: - Private

private extension ExpressInteractor {
    func updateViewForExpressManagerState(_ state: ExpressManagerState) async throws {
        logger.debug("[Swap] \(self) update receive expressManagerState \(state)")

        let state = try await mapState(state: state)
        updateViewState(state)
    }

    func mapState(state: ExpressManagerState) async throws -> ExpressInteractorState {
        switch state {
        case .idle:
            return .idle
        case .restriction(let restriction):
            let state = try await proceedRestriction(restriction: restriction)
            return state
        case .ready(let data):
            let state = try await getReadyToSwapViewState(data: data)

            guard try await hasEnoughBalanceForFee(fees: state.fees) else {
                return .notEnoughAmountForFee
            }

            return .readyToSwap(state: state)
        }
    }

    func updateViewState(_ state: ExpressInteractorState) {
        logger.debug("[Swap] \(self) update state to \(state)")

        _state.send(state)
    }
}

// MARK: - Restriction

private extension ExpressInteractor {
    func proceedRestriction(restriction: ExpressManagerRestriction) async throws -> ExpressInteractorState {
        switch restriction {
        case .permissionRequired(let spender):
            let state = try await getPermissionRequiredViewState(spender: spender)

            guard try await hasEnoughBalanceForFee(fees: state.fees) else {
                return .notEnoughAmountForFee
            }

            return .permissionRequired(state: state)

        case .hasPendingTransaction:
            return .hasPendingTransaction

        case .notEnoughAmountForSwapping:
            return .notEnoughAmountForSwapping
        }
    }

    func hasEnoughBalanceForFee(fees: [FeeOption: Fee]) async throws -> Bool {
        guard let fee = fees[feeOption]?.amount.value else {
            throw ExpressInteractorError.feeNotFound
        }

        let sender = sender.read()

        if sender.isToken {
            let coinBalance = try await sender.getCoinBalance()
            return fee < coinBalance
        }

        guard let amount = expressManager.getAmount() else {
            throw ExpressManagerError.amountNotFound
        }

        let balance = try await sender.getBalance()
        return fee + amount < balance
    }
}

// MARK: - Allowance

private extension ExpressInteractor {
    func approvePolicyDidChange() async throws {
        guard case .permissionRequired(let state) = _state.value else {
            assertionFailure("We can't update policy if we don't needed in the permission")
            return
        }

        let newState = try await getPermissionRequiredViewState(spender: state.spender)
        updateViewState(.permissionRequired(state: newState))
    }

    func getPermissionRequiredViewState(spender: String) async throws -> PermissionRequiredViewState {
        let source = sender.read()
        let contractAddress = source.currency.contractAddress
        assert(contractAddress != ExpressConstants.coinContractAddress)

        let data = try await loadApproveData(wallet: source, spender: spender)

        try Task.checkCancellation()

        // For approve transaction value is always be 0
        let fees = try await getFee(destination: contractAddress, value: 0, hexData: data.hexString)

        return PermissionRequiredViewState(
            spender: spender,
            toContractAddress: contractAddress,
            data: data,
            fees: fees
        )
    }

    func loadApproveData(wallet: ExpressWallet, spender: String) async throws -> Data {
        let amount = try getApproveAmount()

        return try await allowanceProvider.getApproveData(
            owner: wallet.address,
            to: spender,
            contract: wallet.currency.contractAddress,
            amount: amount
        )
    }
}

// MARK: - Swap

private extension ExpressInteractor {
    func getReadyToSwapViewState(data: ExpressTransactionData) async throws -> ReadyToSwapViewState {
        let fees = try await getFee(destination: data.destinationAddress, value: data.value, hexData: data.txData)

        return ReadyToSwapViewState(data: data, fees: fees)
    }
}

// MARK: - Fee

private extension ExpressInteractor {
    func feeOptionDidChange() async throws -> ExpressInteractorState {
        switch _state.value {
        case .permissionRequired(let state):
            if try await hasEnoughBalanceForFee(fees: state.fees) {
                return .notEnoughAmountForFee
            }

            return .permissionRequired(state: state)
        case .readyToSwap(let state):
            if try await hasEnoughBalanceForFee(fees: state.fees) {
                return .notEnoughAmountForFee
            }

            return .readyToSwap(state: state)
        default:
            throw ExpressInteractorError.transactionDataNotFound
        }
    }

    func getFee(destination: String, value: Decimal, hexData: String?) async throws -> [FeeOption: Fee] {
        let sender = sender.read()

        // If EVM network we should pass data in the fee calculation
        if let ethereumNetworkProvider = sender.ethereumNetworkProvider {
            let fees = try await ethereumNetworkProvider.getFee(
                destination: destination,
                value: value.description,
                data: hexData.map { Data(hexString: $0) }
            ).async()

            return [.market: fees[1], .fast: fees[2]]
        }

        let amount = Amount(
            with: sender.blockchainNetwork.blockchain,
            type: sender.amountType,
            value: value
        )

        let fees = try await sender.getFee(amount: amount, destination: destination).async()
        return [.market: fees[1], .fast: fees[2]]
    }
}

// MARK: - Helpers

private extension ExpressInteractor {
    func throwableUpdateTask(block: @escaping (_ interactor: ExpressInteractor) async throws -> Void) {
        updateStateTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await block(self)
            } catch {
                updateViewState(.requiredRefresh(occurredError: error))
            }
        }
    }

    func getApproveAmount() throws -> Decimal {
        switch approvePolicy {
        case .specified:
            if let amount = expressManager.getAmount() {
                return amount
            }

            throw ExpressManagerError.amountNotFound
        case .unlimited:
            return .greatestFiniteMagnitude
        }
    }

    func getAnalyticsFeeType() -> Analytics.ParameterValue? {
        switch feeOption {
        case .market: return .transactionFeeNormal
        case .fast: return .transactionFeeMax
        default: return nil
        }
    }
}

enum ExpressInteractorError: Error {
    case feeNotFound
    case coinBalanceNotFound
    case transactionDataNotFound
}
