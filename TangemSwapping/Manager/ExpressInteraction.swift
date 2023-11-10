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

class CommonAllowanceProvider {
    private let allowanceLimit: ThreadSafeContainer<[ExpressCurrency: Decimal]> = [:]
    // Cached addresses for check approving transactions
    private let pendingTransactions: ThreadSafeContainer<[ExpressCurrency: PendingTransactionState]> = [:]
}

extension CommonAllowanceProvider {
    enum PendingTransactionState: Hashable {
        case pending(destination: String)
    }
}

protocol ExpressPendingTransactionRepository {
    func didSendApproveTransaction(swappingTxData: SwappingTransactionData)
    func didSendSwapTransaction(swappingTxData: SwappingTransactionData)
    
    func hasPending(for network: String) -> Bool
}

protocol AllowanceProvider {
    func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal
    func getApproveData(from spender: String, policy: SwappingApprovePolicy) -> Data

    func getSwappingApprovePolicy() -> SwappingApprovePolicy
    func getSwappingGasPricePolicy() -> SwappingGasPricePolicy
    func isEnoughAllowance() -> Bool
}

struct SwappingItems {
    let from: ExpressWallet
    let to: ExpressWallet?
    let providersIDs: [Int]
}

enum ExpressConstants {
    static let coinContractAddress = "0"
}

extension WalletModel: ExpressWallet {
    var currency: TangemSwapping.ExpressCurrency {
        .init(
            contractAddress: ExpressConstants.coinContractAddress,
            network: tokenItem.networkId
        )
    }
    
    var address: String { defaultAddress }
    
    var decimalCount: Int {
        tokenItem.decimalCount
    }
    
    func getBalance() async throws -> Decimal {
        if let balanceValue {
            return balanceValue
        }
        
        _ = await self.update(silent: true).async()
        return balanceValue ?? 0
    }
    
    func getFee(destination: String, value: Decimal, hexData: String?) async throws -> [SwappingGasPricePolicy : Decimal] {
        
        // If EVM network we should pass data in the fee calculation
        if let ethereumNetworkProvider {
            let fees = try await ethereumNetworkProvider.getFee(
                destination: destination,
                value: value.description,
                data: hexData.map { Data(hexString: $0) }
            ).async()
            
            return [
                .normal: fees[1].amount.value,
                .priority: fees[2].amount.value,
            ]
        }
        
        let amount = Amount(
            with: blockchainNetwork.blockchain,
            type: amountType,
            value: value
        )

        let fees = try await getFee(amount: amount, destination: destination).async()
        return [
            .normal: fees[1].amount.value,
            .priority: fees[2].amount.value,
        ]
    }
    
    
}

enum ExpressManagerState {
    case idle
    case loading(_ type: SwappingManagerRefreshType)
    
    // Restrictions -> Notifications
    // Will be returned after the quote request
    case permissionRequired(expectedAmount: Decimal)
    case hasPendingTransaction(expectedAmount: Decimal)
    case notEnoughAmountForSwapping(expectedAmount: Decimal)
    
    // Will be returned after the swap request
    case ready(data: ExpressTransactionData, fees: [SwappingGasPricePolicy])
    case requiredRefresh(occurredError: Error)
}

enum ExpressProviderState {
    case idle
    case loading
    case loaded(ExpressProvider)
    case error(error: Error)
}
 
class ExpressInteraction {
    // MARK: - Public

    public let state = CurrentValueSubject<SwappingAvailabilityState, Never>(.idle)
    
    public let swappingItems2: CurrentValueSubject<SwappingItems, Never>
    public let selectedProviderState = CurrentValueSubject<ExpressProviderState, Never>(.idle)

    // MARK: - Dependencies

    private let expressAPIProvider: ExpressAPIProvider
    private let allowanceProvider: AllowanceProvider
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let logger: SwappingLogger

//    private let userTokensManager: UserTokensManager
//    private let currencyMapper: CurrencyMapping
//    private let blockchainNetwork: BlockchainNetwork

    // MARK: - Private

    // MARK: - Options

    
    private var swappingItems: ThreadSafeContainer<SwappingItems>
    private var amount: Decimal?
    private var provider: ExpressProvider?
    
    private var approvePolicy: SwappingApprovePolicy = .unlimited
    private var gasPricePolicy: SwappingGasPricePolicy = .normal
    private var updateProvidersTask: Task<Void, Error>?
    private var updateStateTask: Task<Void, Error>?
    private var providers: [ExpressProvider] = []

    init(
        swappingItems: SwappingItems,
        expressAPIProvider: ExpressAPIProvider,
        allowanceProvider: AllowanceProvider,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        logger: SwappingLogger
    ) {
        self.swappingItems = .init(swappingItems)
        self.expressAPIProvider = expressAPIProvider
        self.allowanceProvider = allowanceProvider
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.logger = logger
        
        updateProvidersTask = Task { [weak self] in
            try await self?.updateProviders()
        }
    }
}

// MARK: - Public

extension ExpressInteraction {
    func getAvailabilityState() -> SwappingAvailabilityState {
        state.value
    }

    func getSwappingItems() -> SwappingItems {
        swappingItems.read()
    }

    func getSwappingApprovePolicy() -> SwappingApprovePolicy {
        approvePolicy
    }

    func getSwappingGasPricePolicy() -> SwappingGasPricePolicy {
        gasPricePolicy
    }

    func update(swappingItems: SwappingItems) {
        logger.debug("[Swap] ExpressInteraction will update swappingItems to \(swappingItems)")
        updateState(.idle)
        // Load pair что бы знать доступных провадеров
        // Загрузка провайдеров если не успели
        // Загрузка квотов по доступным провайдерам
        // Выбор выгодного провайдера
        // Показ UI
        
//        swappingManager.update(swappingItems: swappingItems)
//        await swappingManager.refreshBalances()
//        return
    }

    func update(amount: Decimal?) {
        logger.debug("[Swap] ExpressInteraction will update amount to \(amount as Any)")
        self.amount = amount
//        swappingManager.update(amount: amount)
        refresh(type: .full)
    }

    func update(approvePolicy: SwappingApprovePolicy) {
        self.approvePolicy = approvePolicy
        refresh(type: .full)
    }

    func update(gasPricePolicy: SwappingGasPricePolicy) {
        self.gasPricePolicy = gasPricePolicy
        updateState(with: gasPricePolicy)
    }

    func refresh(type: SwappingManagerRefreshType) {
        logger.debug("[Swap] ExpressInteraction received the request for refresh with \(type)")

        guard let amount, amount > 0 else {
            updateState(.idle)
            return
        }

        guard let to = swappingItems.to else {
            updateState(.idle)
            return
        }

        logger.debug("[Swap] ExpressInteraction start refreshing task")
        updateState(.loading(type))
        updateStateTask = Task { [weak self] in
            guard let self else { return }
            let state = await refreshState(for: self.swappingItems.read())
            updateState(state)
        }
    }
    
    func refresh(for swappingItems: SwappingItems, provider: ExpressProvider) async throws -> SwappingAvailabilityState {
        let preview = try await loadSwappingPreviewData(for: swappingItems, providerId: provider.id)
        
        guard !preview.isPermissionRequired else {
            return .preview(preview)
        }
        
        guard preview.isEnoughAmountForSwapping else {
            return .preview(preview)
        }
        
        guard !preview.hasPendingTransaction else {
            return .preview(preview)
        }
        
        let data = try await loadSwappingData(for: swappingItems, providerId: provider.id)
        
        try Task.checkCancellation()
        
        let fees = try await loadFee(source: swappingItems.from, transactionData: data)
        
        // data for send
        // fee for UI
        // selected provider
        //
    }
    
    func refreshState(for swappingItems: SwappingItems) async -> SwappingAvailabilityState  {

        
        do {
            if provider == nil {
                try await updateSelectedProvider(for: swappingItems, amount: amount)
            }
            
            guard let provider = provider else {
                return .requiredRefresh(occurredError: SwappingManagerError.selectedProviderNotFound)
            }
            
            return try await refresh(for: swappingItems, provider: provider)
        } catch {
            return .requiredRefresh(occurredError: error)
        }
    }
    
    func updateSelectedProvider(for swappingItems: SwappingItems, amount: Decimal) async throws {
        // If providers wasn't loaded
        if providers.isEmpty {
            updateProvidersTask?.cancel()
            try await updateProviders()
        }
        
        let availableProviders = try await loadAvailableProviders(for: swappingItems)

        try Task.checkCancellation()
        
        let quotes = try await loadExpressQuote(swappingItems: swappingItems, providers: availableProviders)
        let bestRateProvider = quotes.sorted(by: \.value.expectAmount).first?.key

        provider = bestRateProvider
    }
    
    func loadExpressQuote(
        swappingItems: SwappingItems,
        providers: [ExpressProvider]
    ) async throws -> [ExpressProvider: ExpressQuote] {
        typealias TaskValue = (id: ExpressProvider, quote: ExpressQuote?)

        let quotes: [ExpressProvider: ExpressQuote] = await withTaskGroup(of: TaskValue.self) { [weak self] taskGroup in
            providers.forEach { provider in

                // Run a parallel asynchronous task and collect it into the group
                _ = taskGroup.addTaskUnlessCancelled { [weak self] in
                    guard let self else { 
                        return (provider, nil)
                    }
                    
                    do {
                        let item = try self.makeExpressSwappableItem(items: swappingItems, providerId: provider.id)
                        let quote = try await self.expressAPIProvider.exchangeQuote(item: item)
                        return (provider, quote)
                    } catch {
                        return (provider, nil)
                    }
                }
            }

            return await taskGroup.reduce(into: [:]) { result, tuple in
                if let quote = tuple.quote {
                    result[tuple.id] = quote
                }
            }
        }
        
        return quotes
    }
    
    func makeExpressSwappableItem(items: SwappingItems, providerId: Int) throws -> ExpressSwappableItem {
        guard let to = swappingItems.to else {
            throw SwappingManagerError.destinationNotFound
        }
        
        guard let amount, amount > 0 else {
            throw SwappingManagerError.amountNotFound
        }
        
        return ExpressSwappableItem(
            source: swappingItems.from,
            destination: to,
            amount: amount,
            providerId: providerId
        )
    }
    
    func updateProviders() async throws {
        providers = try await expressAPIProvider.providers()
    }
    
    func loadAvailableProviders(for swappingItems: SwappingItems) async throws -> [ExpressProvider] {
        guard let to = swappingItems.to else {
            throw SwappingManagerError.destinationNotFound
        }
        
        let pairs = try await expressAPIProvider.pairs(from: [swappingItems.from.currency], to: [to.currency])
        
        guard let pair = pairs.first else {
            throw SwappingManagerError.availablePairNotFound
        }

        return providers.filter { pair.providers.contains($0.id) }
    }
    
    // 1. надо ли собирать все ограничения или можно сразу писать их
    func loadSwappingPreviewData(for swappingItems: SwappingItems, providerId: Int) async throws -> SwappingPreviewData {
        let item = try makeExpressSwappableItem(items: swappingItems, providerId: providerId)
        let quote = try await expressAPIProvider.exchangeQuote(item: item)
        
        try Task.checkCancellation()
        
        let isPermissionRequired = try await isPermissionRequired(
            wallet: item.source,
            for: quote.allowanceContract,
            amount: item.amount
        )
        
        try Task.checkCancellation()
        
        let hasPendingTransaction = expressPendingTransactionRepository.hasPending(for: item.source.currency.network)
        let sourceBalance = try await item.source.getBalance()
        let isEnoughAmountForSwapping = item.amount < sourceBalance
        
        return SwappingPreviewData(
            expectedAmount: quote.expectAmount,
            isPermissionRequired: isPermissionRequired,
            hasPendingTransaction: hasPendingTransaction,
            isEnoughAmountForSwapping: isEnoughAmountForSwapping
        )
    }
    
    func isPermissionRequired(wallet: ExpressWallet, for spender: String?, amount: Decimal) async throws -> Bool {
        guard let spender = spender else {
            return false
        }
        
        let contractAddress = wallet.currency.contractAddress

        assert(contractAddress != ExpressConstants.coinContractAddress)
        
        let allowance = try await allowanceProvider.getAllowance(
            owner: wallet.address,
            to: spender,
            contract: contractAddress
        )

        return allowance < amount
    }
    
    func loadSwappingData(for swappingItems: SwappingItems, providerId: Int) async throws -> ExpressTransactionData {
        let item = try makeExpressSwappableItem(items: swappingItems, providerId: providerId)
        let data = try await expressAPIProvider.exchangeData(item: item, destinationAddress: item.destination.address)
        return data
    }
    
    func loadFee(source: ExpressWallet,
                 transactionData: ExpressTransactionData) async throws -> [SwappingGasPricePolicy: Decimal] {
        
        let fees = try await source.getFee(
            destination: transactionData.destinationAddress,
            value: transactionData.value,
            hexData: transactionData.txData
        )

        return fees
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
            switch getSwappingApprovePolicy() {
            case .specified: return .oneTransactionApprove
            case .unlimited: return .unlimitedApprove
            }
        }()

        Analytics.log(event: .transactionSent, params: [
            .commonSource: Analytics.ParameterValue.transactionSourceApprove.rawValue,
            .feeType: getAnalyticsFeeType().rawValue,
            .token: swappingTxData.sourceCurrency.symbol,
            .blockchain: swappingTxData.sourceBlockchain.name,
            .permissionType: permissionType.rawValue,
        ])
    }

    func didSendSwapTransaction(swappingTxData: SwappingTransactionData) {
        expressPendingTransactionRepository.didSendSwapTransaction(swappingTxData: swappingTxData)
        updateState(.idle)

        Analytics.log(event: .transactionSent, params: [
            .commonSource: Analytics.ParameterValue.transactionSourceSwap.rawValue,
            .token: swappingTxData.sourceCurrency.symbol,
            .blockchain: swappingTxData.sourceBlockchain.name,
            .feeType: getAnalyticsFeeType().rawValue,
        ])
    }
}

// MARK: - Private

private extension ExpressInteraction {
    func updateState(_ state: SwappingAvailabilityState) {
        logger.debug("[Swap] ExpressInteraction update state to \(state)")

        self.state.send(state)
    }

    func updateState(with gasPricePolicy: SwappingGasPricePolicy) {
        guard case .available(let model) = getAvailabilityState(),
              let gas = model.gasOptions.first(where: { $0.policy == gasPricePolicy }) else {
            return
        }

        let transactionData = model.transactionData
        let newData = SwappingTransactionData(
            sourceCurrency: transactionData.sourceCurrency,
            sourceBlockchain: transactionData.sourceBlockchain,
            destinationCurrency: transactionData.destinationCurrency,
            sourceAddress: transactionData.sourceAddress,
            destinationAddress: transactionData.destinationAddress,
            txData: transactionData.txData,
            sourceAmount: transactionData.sourceAmount,
            destinationAmount: transactionData.destinationAmount,
            value: transactionData.value,
            gas: gas
        )

        let availabilityModel = SwappingAvailabilityModel(
            transactionData: newData,
            gasOptions: model.gasOptions,
            restrictions: model.restrictions
        )

        updateState(.available(availabilityModel))
    }

    func getAnalyticsFeeType() -> Analytics.ParameterValue {
        switch gasPricePolicy {
        case .normal: return .transactionFeeNormal
        case .priority: return .transactionFeeMax
        }
    }
}
