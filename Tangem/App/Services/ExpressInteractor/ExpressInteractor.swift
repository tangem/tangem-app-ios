//
//  ExpressInteractor.swift
//  Tangem
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
    private let expressTransactionBuilder: ExpressTransactionBuilder
    private let signer: TransactionSigner
    private let logger: SwappingLogger

    // MARK: - Options

    private let _state: CurrentValueSubject<ExpressInteractorState, Never> = .init(.idle)
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
        expressTransactionBuilder: ExpressTransactionBuilder,
        signer: TransactionSigner,
        logger: SwappingLogger
    ) {
        _swappingPair = .init(SwappingPair(sender: sender, destination: nil))
        self.expressManager = expressManager
        self.allowanceProvider = allowanceProvider
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.expressDestinationService = expressDestinationService
        self.expressTransactionBuilder = expressTransactionBuilder
        self.signer = signer
        self.logger = logger

        loadDestinationIfNeeded()
    }
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

    func getAllQuotes() async -> [ExpectedQuote] {
        await expressManager.getAllQuotes()
    }

    func getSelectedProvider() async -> ExpressProvider? {
        await expressManager.getSelectedQuote()?.provider
    }
}

// MARK: - Updates

extension ExpressInteractor {
    func swapPair() {
        guard let destination = _swappingPair.value.destination else {
            log("The destination not found")
            return
        }

        let newPair = SwappingPair(sender: destination, destination: _swappingPair.value.sender)
        _swappingPair.value = newPair

        swappingPairDidChange()
    }

    func update(sender wallet: WalletModel) {
        log("Will update sender to \(wallet)")

        _swappingPair.value.sender = wallet
        swappingPairDidChange()
    }

    func update(destination wallet: WalletModel?) {
        log("Will update destination to \(String(describing: wallet))")

        _swappingPair.value.destination = wallet
        swappingPairDidChange()
    }

    func update(amount: Decimal?) {
        log("Will update amount to \(amount as Any)")

        updateState(.loading(type: .full))
        updateTask { interactor in
            let state = try await interactor.expressManager.updateAmount(amount: amount)
            return try await interactor.mapState(state: state)
        }
    }

    func updateProvider(provider: ExpressProvider) {
        log("Will update provider to \(provider)")

        updateState(.loading(type: .full))
        updateTask { interactor in
            let state = try await interactor.expressManager.updateSelectedProvider(provider: provider)
            return try await interactor.mapState(state: state)
        }
    }

    func updateApprovePolicy(policy: SwappingApprovePolicy) {
        approvePolicy.mutate { $0 = policy }

        updateTask { interactor in
            try await interactor.approvePolicyDidChange()
        }
    }

    func updateFeeOption(option: FeeOption) {
        feeOption.mutate { $0 = option }

        updateTask { interactor in
            try await interactor.feeOptionDidChange()
        }
    }
}

// MARK: - Send

extension ExpressInteractor {
    func send() async throws -> TransactionSendResultState {
        guard let destination = getDestination()?.tokenItem else {
            throw ExpressInteractorError.destinationNotFound
        }

        Analytics.log(
            event: .swapButtonSwap,
            params: [
                .sendToken: getSender().tokenItem.currencySymbol,
                .receiveToken: destination.currencySymbol,
            ]
        )

        let result: TransactionSendResultState = try await {
            switch getState() {
            case .idle, .loading, .restriction:
                throw ExpressInteractorError.transactionDataNotFound
            case .previewCEX(let fees, _):
                return try await sendCEXTransaction(fees: fees)
            case .readyToSwap(let state, _):
                return try await sendDEXTransaction(state: state)
            }
        }()

        updateState(.idle)
        expressPendingTransactionRepository.didSendSwapTransaction()
        return result
    }

    func sendApproveTransaction() async throws {
        guard case .restriction(.permissionRequired(let state), _) = getState() else {
            throw ExpressInteractorError.transactionDataNotFound
        }

        guard let fee = state.fees[getFeeOption()] else {
            throw ExpressInteractorError.feeNotFound
        }

        let sender = getSender()
        let transaction = try await expressTransactionBuilder.makeApproveTransaction(
            wallet: sender,
            data: state.data,
            fee: fee,
            contractAddress: state.toContractAddress
        )
        let result = try await sender.send(transaction, signer: signer).async()
        logger.debug("Sent the approve transaction with result: \(result)")
        expressPendingTransactionRepository.didSendApproveTransaction()
        updateState(.restriction(.hasPendingTransaction, quote: getState().quote))
    }
}

// MARK: - Refresh

extension ExpressInteractor {
    func refresh(type: SwappingManagerRefreshType) {
        log("Did requested for refresh with \(type)")

        updateTask { interactor in
            guard let amount = await interactor.expressManager.getAmount(), amount > 0 else {
                return .idle
            }

            interactor.log("Start refreshing task")
            interactor.updateState(.loading(type: type))

            let state = try await interactor.expressManager.update()
            return try await interactor.mapState(state: state)
        }
    }

    func cancelRefresh() {
        guard updateStateTask != nil else {
            return
        }

        log("Cancel the refreshing task")

        updateStateTask?.cancel()
        updateStateTask = nil
    }
}

// MARK: - Private

private extension ExpressInteractor {
    func swappingPairDidChange() {
        updateTask { interactor in
            guard let destination = interactor.getDestination() else {
                return .restriction(.noDestinationTokens, quote: .none)
            }

            // If we have a amount to we will start the full update
            if let amount = await interactor.expressManager.getAmount(), amount > 0 {
                interactor.updateState(.loading(type: .full))
            }

            let sender = interactor.getSender()
            let pair = ExpressManagerSwappingPair(source: sender, destination: destination)
            let state = try await interactor.expressManager.updatePair(pair: pair)
            return try await interactor.mapState(state: state)
        }
    }

    func mapState(state: ExpressManagerState) async throws -> ExpressInteractorState {
        switch state {
        case .idle:
            return .idle
        case .restriction(let restriction):
            let quote = await expressManager.getSelectedQuote()

            if hasPendingTransaction() {
                return .restriction(.hasPendingTransaction, quote: quote)
            }

            return try await proceedRestriction(restriction: restriction, quote: quote)

        case .previewCEX(let quote):
            guard let expressQuote = await expressManager.getSelectedQuote()?.quote else {
                throw ExpressInteractorError.quoteNotFound
            }

            let address = getSender().defaultAddress
            let fees = try await getFee(destination: address, value: expressQuote.fromAmount, hexData: nil)
            return .previewCEX(fees: fees, quote: quote)

        case .ready(let data):
            guard let quote = await expressManager.getSelectedQuote() else {
                throw ExpressInteractorError.quoteNotFound
            }

            if hasPendingTransaction() {
                return .restriction(.hasPendingTransaction, quote: quote)
            }

            let state = try await getReadyToSwapViewState(data: data)
            guard try await hasEnoughBalanceForFee(fees: state.fees) else {
                return .restriction(.notEnoughAmountForFee, quote: quote)
            }

            return .readyToSwap(state: state, quote: quote)
        }
    }

    func updateState(_ state: ExpressInteractorState) {
        log("Update state to express interactor state \(state)")

        _state.send(state)
    }
}

// MARK: - Restriction

private extension ExpressInteractor {
    func proceedRestriction(restriction: ExpressManagerRestriction, quote: ExpectedQuote?) async throws -> ExpressInteractorState {
        switch restriction {
        case .pairNotFound:
            return .restriction(.noDestinationTokens, quote: quote)
        case .notEnoughAmountForSwapping(let minAmount):
            return .restriction(.notEnoughAmountForSwapping(minAmount: minAmount), quote: quote)

        case .permissionRequired(let spender):
            let state = try await getPermissionRequiredViewState(spender: spender)

            guard try await hasEnoughBalanceForFee(fees: state.fees) else {
                return .restriction(.notEnoughAmountForFee, quote: quote)
            }

            return .restriction(.permissionRequired(state: state), quote: quote)

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
            return fee <= coinBalance
        }

        guard let amount = await expressManager.getAmount() else {
            throw ExpressManagerError.amountNotFound
        }

        let balance = try await sender.getBalance()
        return fee + amount <= balance
    }

    func hasPendingTransaction() -> Bool {
        let network = getSender().expressCurrency.network
        return expressPendingTransactionRepository.hasPending(for: network)
    }
}

// MARK: - Allowance

private extension ExpressInteractor {
    func approvePolicyDidChange() async throws -> ExpressInteractorState {
        guard case .restriction(let type, let quote) = _state.value,
              case .permissionRequired(let state) = type else {
            assertionFailure("We can't update policy if we don't needed in the permission")
            return .idle
        }

        let newState = try await getPermissionRequiredViewState(spender: state.spender)
        return .restriction(.permissionRequired(state: newState), quote: quote)
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
        let wei = wallet.convertToWEI(value: amount)
        return allowanceProvider.makeApproveData(spender: spender, amount: wei)
    }
}

// MARK: - Swap

private extension ExpressInteractor {
    func sendDEXTransaction(state: ExpressSwapData) async throws -> TransactionSendResultState {
        guard let fee = state.fees[getFeeOption()] else {
            throw ExpressInteractorError.feeNotFound
        }

        let sender = getSender()
        let transaction = try await expressTransactionBuilder.makeTransaction(wallet: sender, data: state.data, fee: fee)
        let result = try await sender.send(transaction, signer: signer).async()

        return TransactionSendResultState(data: state.data, hash: result.hash)
    }

    func sendCEXTransaction(fees: [FeeOption: Fee]) async throws -> TransactionSendResultState {
        guard let fee = fees[getFeeOption()] else {
            throw ExpressInteractorError.feeNotFound
        }

        let sender = getSender()
        let data = try await expressManager.requestData()
        let transaction = try await expressTransactionBuilder.makeTransaction(wallet: sender, data: data, fee: fee)
        let result = try await sender.send(transaction, signer: signer).async()

        return TransactionSendResultState(data: data, hash: result.hash)
    }

    func getReadyToSwapViewState(data: ExpressTransactionData) async throws -> ExpressSwapData {
        let fees = try await getFee(destination: data.destinationAddress, value: data.value, hexData: data.txData)

        return ExpressSwapData(data: data, fees: fees)
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
        case .restriction(.permissionRequired(let state), let quote):
            guard try await hasEnoughBalanceForFee(fees: state.fees) else {
                return .restriction(.notEnoughAmountForFee, quote: quote)
            }

            return .restriction(.permissionRequired(state: state), quote: quote)
        case .restriction:
            throw ExpressInteractorError.transactionDataNotFound
        case .previewCEX(let fees, let quote):
            guard try await hasEnoughBalanceForFee(fees: fees) else {
                return .restriction(.notEnoughAmountForFee, quote: quote)
            }

            return .previewCEX(fees: fees, quote: quote)
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

            return mapFeeToDictionary(fees: fees)
        }

        let fees = try await sender.getFee(amount: amount, destination: destination).async()
        return mapFeeToDictionary(fees: fees)
    }

    func mapFeeToDictionary(fees: [Fee]) -> [FeeOption: Fee] {
        switch fees.count {
        case 1:
            return [.market: fees[0]]
        case 3:
            return [.market: fees[1], .fast: fees[2]]
        default:
            return [:]
        }
    }
}

// MARK: - Helpers

private extension ExpressInteractor {
    func updateTask(block: @escaping (_ interactor: ExpressInteractor) async throws -> ExpressInteractorState) {
        cancelRefresh()
        updateStateTask = Task { [weak self] in
            guard let self else { return }

            do {
                let state = try await block(self)

                try Task.checkCancellation()

                updateState(state)
            } catch {
                if error is CancellationError || Task.isCancelled {
                    // Do nothing
                    log("The update task was cancelled")
                    return
                }

                let quote = getState().quote
                updateState(.restriction(.requiredRefresh(occurredError: error), quote: quote))
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

    func loadDestinationIfNeeded() {
        guard getDestination() == nil else {
            log("Swapping item destination has already set")
            return
        }

        let sender = getSender()
        let destination = expressDestinationService.getDestination(source: sender)
        update(destination: destination)
    }
}

// MARK: - Log

private extension ExpressInteractor {
    func log(_ args: Any) {
        logger.debug("[Express] \(self) \(args)")
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
        case restriction(_ type: RestrictionType, quote: ExpectedQuote?)
        case previewCEX(fees: [FeeOption: Fee], quote: ExpectedQuote)
        case readyToSwap(state: ExpressSwapData, quote: ExpectedQuote)

        var fees: [FeeOption: Fee] {
            switch self {
            case .idle, .loading, .restriction:
                return [:]
            case .previewCEX(let fees, _):
                return fees
            case .readyToSwap(let state, _):
                return state.fees
            }
        }

        var quote: ExpectedQuote? {
            switch self {
            case .idle, .loading:
                return nil
            case .restriction(_, let quote):
                return quote
            case .readyToSwap(_, let quote), .previewCEX(_, let quote):
                return quote
            }
        }

        var isAvailableToSendTransaction: Bool {
            switch self {
            case .readyToSwap, .restriction(.permissionRequired, _), .previewCEX:
                return true
            case .idle, .loading, .restriction:
                return false
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
        case noDestinationTokens
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

    struct ExpressSwapData {
        let data: ExpressTransactionData
        let fees: [FeeOption: Fee]
    }

    struct TransactionSendResultState {
        let data: ExpressTransactionData
        let hash: String
    }
}
