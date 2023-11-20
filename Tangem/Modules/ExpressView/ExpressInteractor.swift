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

class ExpressInteractor {
    // MARK: - Public

    public var state: AnyPublisher<ExpressInteractorState, Never> {
        _state.eraseToAnyPublisher()
    }

    public var swappingPair: AnyPublisher<SwappingPair, Never> {
        _swappingPair.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let expressManager: ExpressManager
    private let allowanceProvider: AllowanceProvider
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let expressDestinationService: ExpressDestinationService
    private let signer: TransactionSigner
    private let logger: SwappingLogger

    // MARK: - Options

    private let _state = CurrentValueSubject<ExpressInteractorState, Never>(.idle)
    private let _swappingPair: CurrentValueSubject<SwappingPair, Never>
    private let approvePolicy: ThreadSafeContainer<SwappingApprovePolicy> = .init(.unlimited)
    private let feeOption: ThreadSafeContainer<FeeOption> = .init(.market)

    private var updateStateTask: Task<Void, Error>?

    init(
        sender: WalletModel,
        expressManager: ExpressManager,
        allowanceProvider: AllowanceProvider,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        expressDestinationService: ExpressDestinationService,
        signer: TransactionSigner,
        logger: SwappingLogger
    ) {
        _swappingPair = .init(SwappingPair(sender: sender, destination: nil))

        self.expressManager = expressManager
        self.allowanceProvider = allowanceProvider
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.expressDestinationService = expressDestinationService
        self.signer = signer
        self.logger = logger

        bind()
        loadDestinationIfNeeded()
    }
}

extension ExpressInteractor {
    func bind() {}
}

// MARK: - Getters

extension ExpressInteractor {
    func getState() -> ExpressInteractorState {
        _state.value
    }

    func getSender() -> WalletModel {
        _swappingPair.value.sender
    }

    func getDestination() -> WalletModel? {
        _swappingPair.value.destination
    }

    func getFeeOption() -> FeeOption {
        feeOption.read()
    }

    func getApprovePolicy() -> SwappingApprovePolicy {
        approvePolicy.read()
    }
}

// MARK: - Updates

extension ExpressInteractor {
    func swapPair() {
        guard let destination = _swappingPair.value.destination else {
            logger.debug("[Swap] \(self) The destination not found")
            return
        }

        _swappingPair.value.destination = _swappingPair.value.sender
        _swappingPair.value.sender = destination

        swappingPairDidChange()
    }

    func update(sender wallet: WalletModel) {
        logger.debug("[Swap] \(self) will update sender to \(wallet)")

        _swappingPair.value.sender = wallet
        swappingPairDidChange()
    }

    func update(destination wallet: WalletModel) {
        logger.debug("[Swap] \(self) will update destination to \(wallet)")

        _swappingPair.value.destination = wallet
        swappingPairDidChange()
    }

    func update(amount: Decimal?) {
        logger.debug("[Swap] \(self) will update amount to \(amount as Any)")

        updateViewState(.loading(type: .full))
        throwableUpdateTask { interactor in
            let state = try await interactor.expressManager.updateAmount(amount: amount)
            try await interactor.updateViewForExpressManagerState(state)
        }
    }

    func updateProvider(provider: ExpressProvider) {
        logger.debug("[Swap] \(self) will update provider to \(provider)")

        updateViewState(.loading(type: .full))
        throwableUpdateTask { interactor in
            let state = try await interactor.expressManager.updateSelectedProvider(provider: provider)
            try await interactor.updateViewForExpressManagerState(state)
        }
    }

    func updateApprovePolicy(policy: SwappingApprovePolicy) {
        approvePolicy.mutate { $0 = policy }

        throwableUpdateTask { interactor in
            try await interactor.approvePolicyDidChange()
        }
    }

    func updateFeeOption(option: FeeOption) {
        feeOption.mutate { $0 = option }

        throwableUpdateTask { interactor in
            let state = try await interactor.feeOptionDidChange()
            interactor.updateViewState(state)
        }
    }
}

// MARK: - Send

extension ExpressInteractor {
    struct TransactionSendResultState {
        let data: ExpressTransactionData
        let hash: String
    }

    func send() async throws -> TransactionSendResultState {
        guard case .readyToSwap(let state, _) = getState(),
              let fee = state.fees[getFeeOption()] else {
            throw ExpressInteractorError.transactionDataNotFound
        }

        let sender = getSender()
        let destination = getDestination()?.tokenItem

        Analytics.log(
            event: .swapButtonSwap,
            params: [
                .sendToken: sender.tokenItem.currencySymbol,
                .receiveToken: destination?.currencySymbol ?? "",
            ]
        )

        let transaction = try await sender.makeTransaction(data: state.data, fee: fee)
        let result = try await sender.send(transaction, signer: signer).async()

//        didSendSwapTransaction(swappingTxData: <#T##SwappingTransactionData#>)

        return TransactionSendResultState(data: state.data, hash: result.hash)
    }
}

// MARK: - Refresh

extension ExpressInteractor {
    func refresh(type: SwappingManagerRefreshType) {
        AppLog.shared.debug("[Swap] did requested for refresh with \(type)")

        throwableUpdateTask { interactor in
            guard let amount = await interactor.expressManager.getAmount(), amount > 0 else {
                interactor.updateViewState(.idle)
                return
            }

            AppLog.shared.debug("[Swap] ExpressInteractor start refreshing task")
            interactor.updateViewState(.loading(type: type))

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
}

// MARK: - Private

private extension ExpressInteractor {
    func didSendApproveTransaction(swappingTxData: SwappingTransactionData) {
        expressPendingTransactionRepository.didSendApproveTransaction(swappingTxData: swappingTxData)
        refresh(type: .full)

        let permissionType: Analytics.ParameterValue = {
            switch getApprovePolicy() {
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

    func swappingPairDidChange() {
        guard let destination = getDestination() else {
            logger.debug("[Swap] \(self) The destination not found")
            return
        }

        updateViewState(.loading(type: .full))
        let pair = ExpressManagerSwappingPair(source: getSender(), destination: destination)
        throwableUpdateTask { interactor in
            let state = try await interactor.expressManager.updatePair(pair: pair)
            try await interactor.updateViewForExpressManagerState(state)
        }
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

            guard let quote = await expressManager.getSelectedQuote() else {
                throw ExpressInteractorError.quoteNotFound
            }

            guard try await hasEnoughBalanceForFee(fees: state.fees) else {
                return .restriction(.notEnoughAmountForFee, quote: quote)
            }

            return .readyToSwap(state: state, quote: quote)
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
        guard let quote = await expressManager.getSelectedQuote() else {
            throw ExpressInteractorError.quoteNotFound
        }

        switch restriction {
        case .notEnoughAmountForSwapping(let minAmount):
            return .restriction(.notEnoughAmountForSwapping(minAmount: minAmount), quote: quote)

        case .permissionRequired(let spender):
            let state = try await getPermissionRequiredViewState(spender: spender)

            guard try await hasEnoughBalanceForFee(fees: state.fees) else {
                return .restriction(.notEnoughAmountForFee, quote: quote)
            }

            return .restriction(.permissionRequired(state: state), quote: quote)

        case .hasPendingTransaction:
            return .restriction(.hasPendingTransaction, quote: quote)

        case .notEnoughBalanceForSwapping:
            return .restriction(.notEnoughBalanceForSwapping, quote: quote)
        }
    }

    func hasEnoughBalanceForFee(fees: [FeeOption: Fee]) async throws -> Bool {
        guard let fee = fees[getFeeOption()]?.amount.value else {
            throw ExpressInteractorError.feeNotFound
        }

        let sender = getSender()

        if sender.isToken {
            let coinBalance = try await sender.getCoinBalance()
            return fee < coinBalance
        }

        guard let amount = await expressManager.getAmount() else {
            throw ExpressManagerError.amountNotFound
        }

        let balance = try await sender.getBalance()
        return fee + amount < balance
    }
}

// MARK: - Allowance

private extension ExpressInteractor {
    func approvePolicyDidChange() async throws {
        guard case .restriction(let type, let quote) = _state.value,
              case .permissionRequired(let state) = type else {
            assertionFailure("We can't update policy if we don't needed in the permission")
            return
        }

        let newState = try await getPermissionRequiredViewState(spender: state.spender)
        updateViewState(.restriction(.permissionRequired(state: newState), quote: quote))
    }

    func getPermissionRequiredViewState(spender: String) async throws -> PermissionRequiredViewState {
        let source = getSender()
        let contractAddress = source.expressCurrency.contractAddress
        assert(contractAddress != ExpressConstants.coinContractAddress)

        let data = try await makeApproveData(wallet: source, spender: spender)

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

    func makeApproveData(wallet: ExpressWallet, spender: String) async throws -> Data {
        let amount = try await getApproveAmount()

        return allowanceProvider.makeApproveData(spender: spender, amount: amount)
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
        case .idle:
            return .idle
        case .loading(let type):
            return .loading(type: type)
        case .restriction(let type, let quote):
            switch type {
            case .permissionRequired(let state):
                guard try await hasEnoughBalanceForFee(fees: state.fees) else {
                    return .restriction(.notEnoughAmountForFee, quote: quote)
                }

                return .restriction(.permissionRequired(state: state), quote: quote)

            default:
                throw ExpressInteractorError.transactionDataNotFound
            }
        case .readyToSwap(let state, let quote):
            guard try await hasEnoughBalanceForFee(fees: state.fees) else {
                return .restriction(.notEnoughAmountForFee, quote: quote)
            }

            return .readyToSwap(state: state, quote: quote)
        }
    }

    func getFee(destination: String, value: Decimal, hexData: String?) async throws -> [FeeOption: Fee] {
        let sender = getSender()

        let amount = Amount(
            with: sender.blockchainNetwork.blockchain,
            type: sender.amountType,
            value: value
        )

        // If EVM network we should pass data in the fee calculation
        if let ethereumNetworkProvider = sender.ethereumNetworkProvider {
            let fees = try await ethereumNetworkProvider.getFee(
                destination: destination,
                value: amount.encodedForSend,
                data: hexData.map { Data(hexString: $0) }
            ).async()

            return [.market: fees[1], .fast: fees[2]]
        }

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
                updateViewState(.restriction(.requiredRefresh(occurredError: error), quote: .none))
            }
        }
    }

    func getApproveAmount() async throws -> Decimal {
        switch getApprovePolicy() {
        case .specified:
            if let amount = await expressManager.getAmount() {
                return amount
            }

            throw ExpressManagerError.amountNotFound
        case .unlimited:
            return .greatestFiniteMagnitude
        }
    }

    func getAnalyticsFeeType() -> Analytics.ParameterValue? {
        switch getFeeOption() {
        case .market: return .transactionFeeNormal
        case .fast: return .transactionFeeMax
        default: return nil
        }
    }

    func loadDestinationIfNeeded() {
        guard getDestination() == nil else {
            AppLog.shared.debug("Swapping item destination has already set")
            return
        }

        let sender = getSender()
        runTask(in: self) { [sender] root in
            do {
                let destination = try await root.expressDestinationService.getDestination(source: sender)
                root.update(destination: destination)
            } catch {
                AppLog.shared.debug("Destination load handle error")
                AppLog.shared.error(error)
            }
        }
    }
}

// MARK: - Models

enum ExpressInteractorError: String, LocalizedError {
    case feeNotFound
    case coinBalanceNotFound
    case quoteNotFound
    case transactionDataNotFound
    case destinationNotFound

    var errorDescription: String? {
        #warning("Add Localization")
        return rawValue
    }
}

extension ExpressInteractor {
    enum ExpressInteractorState {
        case idle

        // After change swappingItems
        case loading(type: SwappingManagerRefreshType)
        case restriction(_ type: RestrictionType, quote: ExpressAvailabilityQuoteState?)
        case readyToSwap(state: ReadyToSwapViewState, quote: ExpressAvailabilityQuoteState)

        var quote: ExpressAvailabilityQuoteState? {
            switch self {
            case .idle, .loading:
                return nil
            case .restriction(_, let quote):
                return quote
            case .readyToSwap(_, let quote):
                return quote
            }
        }
    }

    enum RestrictionType {
        case notEnoughAmountForSwapping(minAmount: Decimal)
        case permissionRequired(state: PermissionRequiredViewState)
        case hasPendingTransaction
        case notEnoughBalanceForSwapping
        case notEnoughAmountForFee
        case requiredRefresh(occurredError: Error)
    }

    struct SwappingPair {
        var sender: WalletModel
        var destination: WalletModel?
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
