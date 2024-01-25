//
//  VisaWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemVisa

class VisaWalletModel {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.keysManager) private var keysManager: KeysManager

    private let transactionHistoryService: VisaTransactionHistoryService
    private var visaBridgeInteractor: VisaBridgeInteractor?

    var accountAddress: String { visaBridgeInteractor?.accountAddress ?? .unknown }

    var walletDidChangePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var balancesPublisher: AnyPublisher<AppVisaBalances?, Never> {
        balancesSubject.eraseToAnyPublisher()
    }

    var limitsPublisher: AnyPublisher<AppVisaLimits?, Never> {
        limitsSubject.eraseToAnyPublisher()
    }

    var balances: AppVisaBalances? {
        balancesSubject.value
    }

    var limits: AppVisaLimits? {
        limitsSubject.value
    }

    var transactionHistoryStatePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        transactionHistoryService.statePublisher
    }

    var transactionHistoryItems: [TransactionListItem] {
        let historyMapper = VisaTransactionHistoryMapper(currencySymbol: tokenItem.currencySymbol)
        return historyMapper.mapTransactionListItem(from: transactionHistoryService.items)
    }

    var canFetchMoreTransactionHistory: Bool {
        transactionHistoryService.canFetchMoreHistory
    }

    let tokenItem: TokenItem

    private let balancesSubject = CurrentValueSubject<AppVisaBalances?, Never>(nil)
    private let limitsSubject = CurrentValueSubject<AppVisaLimits?, Never>(nil)
    private let stateSubject = CurrentValueSubject<State, Never>(.notInitialized)

    private var updateTask: Task<Void, Never>?
    private var historyReloadTask: Task<Void, Never>?

    init(userWalletModel: UserWalletModel) {
        let utils = VisaUtilities()
        tokenItem = .token(utils.visaToken, utils.visaBlockchain)

        let apiService = VisaAPIServiceBuilder().build(
            isTestnet: true,
            urlSessionConfiguration: .defaultConfiguration,
            logger: AppLog.shared
        )
        let cardPublicKey: String
        if let wallet = userWalletModel.userWallet.card.wallets.first(where: { $0.curve == .secp256k1 }) {
            cardPublicKey = wallet.publicKey.hexString
        } else {
            cardPublicKey = "Failed to find secp256k1 key"
        }

        transactionHistoryService = VisaTransactionHistoryService(
            cardPublicKey: cardPublicKey,
            apiService: apiService
        )

        setupBridgeInteractor(using: userWalletModel)
    }

    func exploreURL() -> URL? {
        let linkProvider = ExternalLinkProviderFactory().makeProvider(for: tokenItem.blockchain)
        return linkProvider.url(address: accountAddress, contractAddress: tokenItem.token?.contractAddress)
    }

    func startGeneralUpdate() {
        guard updateTask == nil else {
            return
        }

        updateTask = Task { [weak self] in
            await self?.generalUpdateAsync()
            self?.updateTask = nil
        }
    }

    func generalUpdateAsync() async {
        await withTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }

            stateSubject.send(.loading)
            group.addTask {
                guard let currencyId = self.tokenItem.currencyId else {
                    return
                }

                await self.quotesRepository.loadQuotes(currencyIds: [currencyId])
            }

            group.addTask { await self.loadBalancesAndLimits() }

            group.addTask { await self.reloadHistoryAsync() }

            await group.waitForAll()
            stateSubject.send(.idle)
        }
    }

    func reloadHistory() {
        guard historyReloadTask == nil else {
            return
        }

        historyReloadTask = Task { [weak self] in
            await self?.reloadHistoryAsync()
            self?.historyReloadTask = nil
        }
    }

    func loadNextHistoryPage() {
        guard historyReloadTask == nil else {
            return
        }

        historyReloadTask = Task { [weak self] in
            do {
                try await self?.transactionHistoryService.loadNextPage()
            } catch {
                AppLog.shared.error(error)
            }
            self?.historyReloadTask = nil
        }
    }

    private func setupBridgeInteractor(using userWalletModel: UserWalletModel) {
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem == tokenItem
        }) else {
            stateSubject.send(.failedToInitialize(.missingRequiredBlockchain))
            return
        }

        stateSubject.send(.loading)
        let smartContractInteractor: EVMSmartContractInteractor
        do {
            let factory = EVMSmartContractInteractorFactory(config: keysManager.blockchainConfig)
            smartContractInteractor = try factory.makeInteractor(for: tokenItem.blockchain)
        } catch {
            stateSubject.send(.failedToInitialize(.invalidBlockchain))
            return
        }

        Task { [weak self] in
            guard let self else { return }

            let builder = VisaBridgeInteractorBuilder(evmSmartContractInteractor: smartContractInteractor)
            do {
                let interactor = try await builder.build(for: walletModel.defaultAddress, logger: AppLog.shared)
                visaBridgeInteractor = interactor
                await generalUpdateAsync()
            } catch {
                stateSubject.send(.failedToInitialize(.noPaymentAccount))
            }
        }
    }

//    private func setupTransactionHistoryService(using userWalletModel: UserWalletModel) {
    ////        let cardPublicKey = userWalletModel.userWallet.card.cardPublicKey.hexString
//        let cardPublicKey = "03DEF02B1FECC8BD3CFD52CE93235194479E1DE931EF0F55DC194967E7CCC3D12C"
//        let apiService = VisaAPIServiceBuilder().build(isTestnet: true, urlSessionConfiguration: .defaultConfiguration, logger: AppLog.shared)
//        let dateFrom = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
//        let dateTo = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        let dateFromString = dateFormatter.string(from: dateFrom)
//        let dateToString = dateFormatter.string(from: dateTo)
//        log("Loading history from \(dateFromString) till \(dateToString)")
//        Task {
//            do {
//                let history = try await apiService.loadHistoryPage(request: VisaTransactionHistoryDTO.APIRequest(cardPublicKey: cardPublicKey, dateFrom: dateFromString, dateTo: dateToString))
//                self.log("History loaded: \(history)")
//            } catch {
//                self.log("Failed to load tx history. Error: \(error)")
//            }
//        }
//    }

    private func updateBalanceAndLimits() {
        Task { [weak self] in
            await self?.loadBalancesAndLimits()
        }
    }

    private func loadBalancesAndLimits() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.updateBalances() }
            group.addTask { [weak self] in await self?.updateLimits() }

            await group.waitForAll()
        }
    }

    private func updateBalances() async {
        guard let visaBridgeInteractor else {
            return
        }

        do {
            let balances = try await visaBridgeInteractor.loadBalances()
            balancesSubject.send(.init(balances: balances))
        } catch {
            balancesSubject.send(nil)
        }
    }

    private func updateLimits() async {
        guard let visaBridgeInteractor else {
            return
        }

        do {
            let limits = try await visaBridgeInteractor.loadLimits()
            limitsSubject.send(.init(limits: limits))
        } catch {
            limitsSubject.send(nil)
        }
    }

    private func reloadHistoryAsync() async {
        await transactionHistoryService.reloadHistory()
    }

    private func log(_ message: @autoclosure () -> String) {
        AppLog.shared.debug("\n\n[VisaWalletModel] \(message())\n\n")
    }
}

extension VisaWalletModel: VisaWalletMainHeaderSubtitleDataSource {
    var fiatBalance: String {
        BalanceFormatter().formatFiatBalance(fiatValue)
    }

    var blockchainName: String {
        "Polygon PoS"
    }

    private var fiatValue: Decimal? {
        guard
            let balanceValue = balancesSubject.value?.available,
            let currencyId = tokenItem.currencyId
        else {
            return nil
        }

        let converter = BalanceConverter()
        return converter.convertToFiat(value: balanceValue, from: currencyId)
    }
}

extension VisaWalletModel: MainHeaderBalanceProvider {
    var balanceProvider: AnyPublisher<LoadingValue<NSAttributedString>, Never> {
        stateSubject.combineLatest(balancesSubject)
            .map { [weak self] state, balances -> LoadingValue<NSAttributedString> in
                guard let self else {
                    return .loading
                }

                switch state {
                case .notInitialized, .loading:
                    return .loading
                case .failedToInitialize(let error):
                    return .failedToLoad(error: error)
                case .idle:
                    if let balances {
                        let balanceFormatter = BalanceFormatter()
                        let formattedBalance = balanceFormatter.formatCryptoBalance(balances.available, currencyCode: tokenItem.currencySymbol)
                        let formattedForMain = balanceFormatter.formatTotalBalanceForMain(fiatBalance: formattedBalance, formattingOptions: .defaultOptions)
                        return .loaded(formattedForMain)
                    } else {
                        return .loading
                    }
                }
            }
            .eraseToAnyPublisher()
    }
}

extension VisaWalletModel {
    enum State: Hashable {
        case notInitialized
        case loading
        case failedToInitialize(ModelError)
        case idle
    }

    enum ModelError: Error, Hashable {
        case missingRequiredBlockchain
        case invalidBlockchain
        case noPaymentAccount

        var notificationEvent: VisaNotificationEvent {
            switch self {
            case .missingRequiredBlockchain: return .missingRequiredBlockchain
            case .invalidBlockchain: return .notValidBlockchain
            case .noPaymentAccount: return .failedToLoadPaymentAccount
            }
        }
    }
}
