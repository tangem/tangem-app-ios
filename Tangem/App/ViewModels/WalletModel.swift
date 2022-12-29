//
//  WalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

// [REDACTED_TODO_COMMENT]

class WalletModel: ObservableObject, Identifiable {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    lazy var walletDidChange: AnyPublisher<WalletModel.State, Never> = {
        Publishers.CombineLatest($state.dropFirst(), $rates.dropFirst())
            .map { $0.0 } // Move on latest value state
            .share()
            .eraseToAnyPublisher()
    }()

    @Published var state: State = .created
    @Published var rates: [String: Decimal] = [:]

    var wallet: Wallet { walletManager.wallet }

    var addressNames: [String] {
        wallet.addresses.map { $0.localizedName }
    }

    var isTestnet: Bool {
        wallet.blockchain.isTestnet
    }

    var incomingPendingTransactions: [PendingTransaction] {
        wallet.pendingIncomingTransactions.map {
            PendingTransaction(amountType: $0.amount.type,
                               destination: $0.sourceAddress,
                               transferAmount: $0.amount.string(with: 8),
                               canBePushed: false,
                               direction: .incoming)
        }
    }

    var outgoingPendingTransactions: [PendingTransaction] {
        // let txPusher = walletManager as? TransactionPusher

        return wallet.pendingOutgoingTransactions.map {
            // let isTxStuckByTime = Date().timeIntervalSince($0.date ?? Date()) > Constants.bitcoinTxStuckTimeSec

            return PendingTransaction(amountType: $0.amount.type,
                                      destination: $0.destinationAddress,
                                      transferAmount: $0.amount.string(with: 8),
                                      canBePushed: false, // (txPusher?.isPushAvailable(for: $0.hash ?? "") ?? false) && isTxStuckByTime, //[REDACTED_TODO_COMMENT]
                                      direction: .outgoing)
        }
    }

    var isEmptyIncludingPendingIncomingTxs: Bool {
        wallet.isEmpty && incomingPendingTransactions.isEmpty
    }

    var blockchainNetwork: BlockchainNetwork {
        if wallet.publicKey.derivationPath == nil { // cards without hd wallet
            return BlockchainNetwork(wallet.blockchain, derivationPath: nil)
        }

        return .init(wallet.blockchain, derivationPath: wallet.publicKey.derivationPath)
    }

    var isDemo: Bool { demoBalance != nil }
    var demoBalance: Decimal?

    let walletManager: WalletManager

    private let derivationStyle: DerivationStyle?
    private var latestUpdateTime: Date? = nil
    private var updatePublisher: PassthroughSubject<Void, Error>?
    private var updateTimer: AnyCancellable?
    private var updateWalletModelBag: AnyCancellable?
    private var bag = Set<AnyCancellable>()
    private var updateQueue = DispatchQueue(label: "walletModel_update_queue")

    deinit {
        print("🗑 WalletModel deinit")
    }

    init(walletManager: WalletManager, derivationStyle: DerivationStyle?) {
        self.walletManager = walletManager
        self.derivationStyle = derivationStyle

        bind()
    }

    func bind() {
        AppSettings.shared
            .$selectedCurrencyCode
            .dropFirst()
            .receive(on: updateQueue)
            .setFailureType(to: Error.self)
            .flatMap { [weak self] _ in
                self?.loadRates() ?? .justWithError(output: [:])
            }
            .receive(on: updateQueue)
            .receiveValue { [weak self] in self?.updateRatesIfNeeded($0) }
            .store(in: &bag)
    }

    // MARK: - Update wallet model

    @discardableResult
    func update(silent: Bool) -> AnyPublisher<Void, Error> {
        // If updating already in process return updating Publisher
        if let updatePublisher = updatePublisher {
            return updatePublisher.eraseToAnyPublisher()
        }

        // Keep this before the async call
        let newUpdatePublisher = PassthroughSubject<Void, Error>()
        self.updatePublisher = newUpdatePublisher

        // Check if time interval after latest update not enough
        guard checkLatestUpdateTime(silent: silent) else {
            return newUpdatePublisher.eraseToAnyPublisher()
        }

        if case .loading = state {
            return newUpdatePublisher.eraseToAnyPublisher()
        }

        if !silent {
            updateState(.loading)
        }

        updateWalletModelBag = updateWalletManager()
            .receive(on: updateQueue)
            .flatMap { [weak self] result -> AnyPublisher<(WalletManagerUpdateResult, [String: Decimal]), Error> in
                guard let self else {
                    return .anyFail(error: CommonError.objectReleased)
                }

                return self.loadRates()
                    .map { (result, $0) }
                    .eraseToAnyPublisher()
            }
            .receive(on: updateQueue)
            .sink { [weak self] completion in
                guard let self, case let .failure(error) = completion else { return }

                Analytics.log(error: error)
                self.updateRatesIfNeeded([:])
                self.updateState(.failed(error: error.localizedDescription))
                self.updatePublisher?.send(completion: .failure(error))
                self.updatePublisher = nil

            } receiveValue: { [weak self] updatedResult, rates in
                guard let self else { return }

                self.updateRatesIfNeeded(rates)

                switch updatedResult {
                case .noAccount(let message):
                    self.updateState(.noAccount(message: message))
                case .success:
                    self.updateState(.idle)
                }

                self.updatePublisher?.send(())
                self.updatePublisher?.send(completion: .finished)
                self.updatePublisher = nil
            }

        return newUpdatePublisher.eraseToAnyPublisher()
    }

    func updateWalletManager() -> AnyPublisher<WalletManagerUpdateResult, Error> {
        Future { promise in
            self.updateQueue.sync {
                print("🔄 Updating wallet model for \(self.wallet.blockchain)")
                self.walletManager.update { [weak self] result in
                    let blockchainName = self?.wallet.blockchain.displayName ?? ""
                    print("🔄 Finished updating wallet model for \(blockchainName) result: \(result)")

                    switch result {
                    case .success:
                        self?.latestUpdateTime = Date()

                        if let demoBalance = self?.demoBalance {
                            self?.walletManager.wallet.add(coinValue: demoBalance)
                        }

                        promise(.success(.success))

                    case let .failure(error):
                        switch error as? WalletError {
                        case .noAccount(let message):
                            promise(.success(.noAccount(message: message)))
                        default:
                            promise(.failure(error.detailedError))
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func checkLatestUpdateTime(silent: Bool) -> Bool {
        guard let latestUpdateTime = latestUpdateTime,
              latestUpdateTime.distance(to: Date()) <= 10 else {
            return true
        }

        if !silent {
            self.state = .idle
        }

        self.updatePublisher?.send(())
        self.updatePublisher?.send(completion: .finished)
        self.updatePublisher = nil
        return false
    }

    private func updateState(_ state: State) {
        guard self.state != state else {
            print("Duplicate request to WalletModel state")
            return
        }

        print("🔄 Update state \(state) in WalletModel: \(blockchainNetwork.blockchain.displayName)")
        DispatchQueue.main.async { [weak self] in // captured as weak at call stack
            self?.state = state
        }
    }

    // MARK: - Load Rates

    private func loadRates() -> AnyPublisher<[String: Decimal], Error> {
        var currenciesToExchange = [walletManager.wallet.blockchain.currencyId]
        currenciesToExchange += walletManager.cardTokens.compactMap { $0.id }

        print("🔄 Start loading rates for \(self.wallet.blockchain)")

        return tangemApiService
            .loadRates(for: currenciesToExchange)
            .eraseToAnyPublisher()
    }

    func updateRatesIfNeeded(_ rates: [String: Decimal]) {
        if !self.rates.isEmpty && rates.isEmpty {
            print("🔴 New rates for \(wallet.blockchain) isEmpty")
            return
        }

        print("🔄 Update rates for \(wallet.blockchain)")
        DispatchQueue.main.async {
            self.rates = rates
        }
    }

    // MARK: - Manage tokens

    func getTokens() -> [Token] {
        walletManager.cardTokens
    }

    func addTokens(_ tokens: [Token]) {
        latestUpdateTime = nil

        tokens.forEach {
            if walletManager.cardTokens.contains($0) {
                walletManager.removeToken($0)
            }
        }

        walletManager.addTokens(tokens)
    }

    func canRemove(amountType: Amount.AmountType) -> Bool {
        if amountType == .coin && !walletManager.cardTokens.isEmpty {
            return false
        }

        return true
    }

    func removeToken(_ token: Token) {
        guard canRemove(amountType: .token(value: token)) else {
            assertionFailure("Delete token isn't possible")
            return
        }

        walletManager.removeToken(token)
    }

    func startUpdatingTimer() {
        latestUpdateTime = nil
        print("⏰ Starting updating timer for Wallet model")
        updateTimer = Timer.TimerPublisher(interval: 10.0,
                                           tolerance: 0.1,
                                           runLoop: .main,
                                           mode: .common)
            .autoconnect()
            .sink() { [weak self] _ in
                print("⏰ Updating timer alarm ‼️ Wallet model will be updated")
                self?.update(silent: false)
                self?.updateTimer?.cancel()
            }
    }

    func send(_ tx: Transaction, signer: TangemSigner) -> AnyPublisher<Void, Error> {
        if isDemo {
            return signer.sign(hash: Data.randomData(count: 32),
                               walletPublicKey: wallet.publicKey)
                .mapVoid()
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }

        return walletManager.send(tx, signer: signer)
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.startUpdatingTimer()
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        if isDemo {
            let demoFees = DemoUtil().getDemoFee(for: walletManager.wallet.blockchain)
            return .justWithError(output: demoFees)
        }

        return walletManager.getFee(amount: amount, destination: destination)
    }
}

// MARK: - Helpers

extension WalletModel {
    func currencyId(for amount: Amount.AmountType) -> String? {
        switch amount {
        case .coin, .reserve:
            return walletManager.wallet.blockchain.currencyId
        case .token(let token):
            return token.id
        }
    }

    func getRateFormatted(for amountType: Amount.AmountType) -> String {
        var rateString = ""

        if let currencyId = self.currencyId(for: amountType),
           let rate = rates[currencyId] {
            rateString = rate.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
        }

        return rateString
    }


    func getQRReceiveMessage(for amountType: Amount.AmountType? = nil)  -> String {
        let type: Amount.AmountType = amountType ?? wallet.amounts.keys.first(where: { $0.isToken }) ?? .coin
        // todo: handle default token
        let symbol = wallet.amounts[type]?.currencySymbol ?? wallet.blockchain.currencySymbol

        let currencyName: String
        if case let .token(token) = amountType {
            currencyName = token.name
        } else {
            currencyName = wallet.blockchain.displayName
        }

        return Localization.addressQrCodeMessageFormat(currencyName, symbol, wallet.blockchain.displayName)
    }

    func getFiatFormatted(for amount: Amount?, roundingMode: NSDecimalNumber.RoundingMode = .down) -> String? {
        return getFiat(for: amount, roundingMode: roundingMode)?.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
    }

    func getFiat(for amount: Amount?, roundingMode: NSDecimalNumber.RoundingMode = .down) -> Decimal? {
        if let amount = amount {
            return getFiat(for: amount.value, currencyId: currencyId(for: amount.type), roundingMode: roundingMode)
        }
        return nil
    }

    func getFiat(for value: Decimal, currencyId: String?, roundingMode: NSDecimalNumber.RoundingMode = .down) -> Decimal? {
        if let currencyId = currencyId,
           let rate = rates[currencyId]
        {
            let fiatValue = value * rate
            if fiatValue == 0 {
                return 0
            }
            return max(fiatValue, 0.01).rounded(scale: 2, roundingMode: roundingMode)
        }
        return nil
    }

    func getCrypto(for amount: Amount?) -> Decimal? {
        guard
            let amount = amount,
            let currencyId = self.currencyId(for: amount.type)
        else {
            return nil
        }

        if let rate = rates[currencyId] {
            return (amount.value / rate).rounded(scale: amount.decimals)
        }
        return nil
    }

    func displayAddress(for index: Int) -> String {
        wallet.addresses[index].value
    }

    func shareAddressString(for index: Int) -> String {
        wallet.getShareString(for: wallet.addresses[index].value)
    }

    func exploreURL(for index: Int) -> URL? {
        if isDemo {
            return nil
        }

        return wallet.getExploreURL(for: wallet.addresses[index].value)
    }

    func getDecimalBalance(for type: Amount.AmountType) -> Decimal? {
        return wallet.amounts[type]?.value
    }

    func getBalance(for type: Amount.AmountType) -> String {
        return wallet.amounts[type].map { $0.string(with: 8) } ?? ""
    }

    func getFiatBalance(for type: Amount.AmountType) -> String {
        let amount = wallet.amounts[type] ?? Amount(with: wallet.blockchain, type: type, value: .zero)
        return getFiatFormatted(for: amount, roundingMode: .plain) ?? "–"
    }

    func isCustom(_ amountType: Amount.AmountType) -> Bool {
        if state.isLoading {
            return false
        }

        guard let derivationStyle = derivationStyle else {
            return false
        }

        let defaultDerivation = wallet.blockchain.derivationPath(for: derivationStyle)
        let currentDerivation = blockchainNetwork.derivationPath

        if currentDerivation != defaultDerivation {
            return true
        }

        switch amountType {
        case .coin, .reserve:
            return false
        case .token(let token):
            return token.id == nil
        }
    }
}

extension WalletModel {
    func balanceViewModel() -> BalanceViewModel {
        BalanceViewModel(
            isToken: false,
            hasTransactionInProgress: wallet.hasPendingTx,
            state: state,
            name:  wallet.blockchain.displayName,
            fiatBalance: getFiatBalance(for: .coin),
            balance: getBalance(for: .coin),
            secondaryBalance: "",
            secondaryFiatBalance: "",
            secondaryName: ""
        )
    }

    func tokenBalanceViewModels() -> [TokenBalanceViewModel] {
        walletManager.cardTokens.map {
            let type = Amount.AmountType.token(value: $0)
            return TokenBalanceViewModel(
                token: $0,
                balance: getBalance(for: type),
                fiatBalance: getFiatBalance(for: type)
            )
        }
    }

    func blockchainTokenItemViewModel() -> TokenItemViewModel {
        let amountType = Amount.AmountType.coin
        let balanceViewModel = balanceViewModel()

        return TokenItemViewModel(
            state: state,
            name: balanceViewModel.name,
            balance: balanceViewModel.balance,
            fiatBalance: balanceViewModel.fiatBalance,
            rate: getRateFormatted(for: amountType),
            fiatValue: getFiat(for: wallet.amounts[amountType], roundingMode: .plain) ?? 0,
            blockchainNetwork: blockchainNetwork,
            amountType: amountType,
            hasTransactionInProgress: wallet.hasPendingTx(for: amountType),
            isCustom: isCustom(amountType)
        )
    }

    func allTokenItemViewModels() -> [TokenItemViewModel] {
        let tokenViewModels = tokenBalanceViewModels().map { balanceViewModel in
            let amountType = Amount.AmountType.token(value: balanceViewModel.token)

            return TokenItemViewModel(
                state: state,
                name: balanceViewModel.name,
                balance: balanceViewModel.balance,
                fiatBalance: balanceViewModel.fiatBalance,
                rate: getRateFormatted(for: amountType),
                fiatValue: getFiat(for: wallet.amounts[amountType]) ?? 0,
                blockchainNetwork: blockchainNetwork,
                amountType: amountType,
                hasTransactionInProgress: wallet.hasPendingTx(for: amountType),
                isCustom: isCustom(amountType)
            )
        }

        return [blockchainTokenItemViewModel()] + tokenViewModels
    }
}

extension WalletModel {
    enum State: Hashable {
        case created
        case idle
        case loading
        case noAccount(message: String)
        case failed(error: String)
        case noDerivation

        var isLoading: Bool {
            switch self {
            case .loading, .created:
                return true
            default:
                return false
            }
        }

        var isSuccesfullyLoaded: Bool {
            switch self {
            case .idle, .noAccount:
                return true
            default:
                return false
            }
        }

        var isBlockchainUnreachable: Bool {
            switch self {
            case .failed:
                return true
            default:
                return false
            }
        }

        var isNoAccount: Bool {
            switch self {
            case .noAccount:
                return true
            default:
                return false
            }
        }

        var errorDescription: String? {
            switch self {
            case .failed(let localizedDescription):
                return localizedDescription
            case .noAccount(let message):
                return message
            default:
                return nil
            }
        }

        var failureDescription: String? {
            switch self {
            case .failed(let localizedDescription):
                return localizedDescription
            default:
                return nil
            }
        }

        fileprivate var canCreateOrPurgeWallet: Bool {
            switch self {
            case .failed, .loading, .created, .noDerivation:
                return false
            case .noAccount, .idle:
                return true
            }
        }
    }

    enum WalletManagerUpdateResult: Hashable {
        case success
        case noAccount(message: String)
    }
}
