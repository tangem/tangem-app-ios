//
//  MainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk
import TangemSdk

class MainViewModel: ObservableObject {
    // MARK: Dependencies -
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.appWarningsService) private var warningsService: AppWarningsProviding
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable
    @Injected(\.rateAppService) private var rateAppService: RateAppService
    @Injected(\.onboardingStepsSetupService) private var cardOnboardingStepSetupService: OnboardingStepsSetupService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Published variables

    @Published var error: AlertBinder?
    @Published var showTradeSheet: Bool = false
    @Published var showSelectWalletSheet: Bool = false
    @Published var isScanning: Bool = false
    @Published var isCreatingWallet: Bool = false
    @Published var image: UIImage? = nil
    @Published var selectedAddressIndex: Int = 0
    @Published var showExplorerURL: URL? = nil
    @Published var showQR: Bool = false
    @Published var state: ScanResult = .unsupported {
        willSet {
            print("⚠️ Reset bag")
            image = nil
            bag = Set<AnyCancellable>()
        }
        didSet {
            bind()
        }
    }

    @Published var isOnboardingModal: Bool = true

    @ObservedObject var warnings: WarningsContainer = .init() {
        didSet {
            warnings.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [unowned self] in
                    withAnimation {
                        self.objectWillChange.send()
                    }
                })
                .store(in: &bag)
        }
    }

    // MARK: Variables
    var isLoadingTokensBalance: Bool = false
    lazy var totalSumBalanceViewModel: TotalSumBalanceViewModel = .init()

    private var bag = Set<AnyCancellable>()
    private var isHashesCounted = false
    private var isProcessingNewCard = false
    private var refreshCancellable: AnyCancellable? = nil
    private lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()

    private unowned let coordinator: MainRoutable

    public var canCreateTwinWallet: Bool {
        if isTwinCard {
            if let cm = cardModel, cm.isNotPairedTwin {
                let wallets = cm.wallets?.count ?? 0
                if wallets > 0 {
                    return cm.isSuccesfullyLoaded
                } else {
                    return true
                }
            }
        }

        return true
    }

    public var hasMultipleButtons: Bool {
        if canCreateWallet {
            return true
        }

        if !canCreateWallet
            && canBuyCrypto
            && !(cardModel?.cardInfo.isMultiWallet ?? true)  {
            return true
        }

        if let cardModel = self.cardModel, !cardModel.cardInfo.isMultiWallet,
           (!canCreateWallet || (cardModel.isTwinCard && cardModel.hasBalance)) {
            return true
        }

        return false
    }


    public var canCreateWallet: Bool {
        if isTwinCard {
            return cardModel?.canCreateTwinCard ?? false
        }

        if let state = cardModel?.state,
           case .empty = state {
            return true
        }

        return false
    }

    public var canSend: Bool {
        guard let model = cardModel else {
            return false
        }

        guard model.canSign else {
            return false
        }

        guard let wallet = wallets?.first else {
            return false
        }

        return wallet.canSend(amountType: .coin)
    }

    var cardModel: CardViewModel? {
        state.cardModel
    }

    var wallets: [Wallet]? {
        cardModel?.wallets
    }

    var currenyCode: String {
        wallets?.first?.blockchain.currencySymbol ?? .unknown
    }

    var canBuyCrypto: Bool {
        cardModel?.canExchangeCrypto ?? false && buyCryptoURL != nil
    }

    var canSellCrypto: Bool {
        cardModel?.canExchangeCrypto ?? false && sellCryptoURL != nil
    }

    var buyCryptoURL: URL? {
        if let wallet = wallets?.first {
            let blockchain = wallet.blockchain
            if blockchain.isTestnet {
                return blockchain.testnetFaucetURL
            }

            return exchangeService.getBuyUrl(currencySymbol: wallet.blockchain.currencySymbol,
                                             amountType: .coin,
                                             blockchain: wallet.blockchain,
                                             walletAddress: wallet.address)
        }
        return nil
    }

    var sellCryptoURL: URL? {
        if let wallet = wallets?.first {
            return exchangeService.getSellUrl(currencySymbol: wallet.blockchain.currencySymbol,
                                              amountType: .coin,
                                              blockchain: wallet.blockchain,
                                              walletAddress: wallet.address)
        }

        return nil
    }

    var buyCryptoCloseUrl: String {
        exchangeService.successCloseUrl.removeLatestSlash()
    }

    var sellCryptoCloseUrl: String {
        exchangeService.sellRequestUrl.removeLatestSlash()
    }

    var incomingTransactions: [PendingTransaction] {
        cardModel?.walletModels?.first?.incomingPendingTransactions ?? []
    }

    var outgoingTransactions: [PendingTransaction] {
        cardModel?.walletModels?.first?.outgoingPendingTransactions ?? []
    }

    var cardNumber: Int? {
        guard let cardInfo = cardModel?.cardInfo else { return nil }

        if let twinNumber = cardInfo.twinCardInfo?.series.number {
            return twinNumber
        }

        if cardInfo.isTangemWallet,
           let backupStatus = cardInfo.card.backupStatus, case .active = backupStatus {
            return 1
        }

        return nil
    }

    var totalCards: Int? {
        guard let cardInfo = cardModel?.cardInfo else { return nil }

        if cardInfo.twinCardInfo?.series.number != nil {
            return 2
        }

        if cardInfo.isTangemWallet,
           let backupStatus = cardInfo.card.backupStatus, case let .active(backupCards) = backupStatus {
            return backupCards + 1
        }

        return nil
    }

    var isTwinCard: Bool {
        cardModel?.isTwinCard ?? false
    }

    var isBackupAllowed: Bool {
        if let cardModel = cardModel {
            return cardModel.cardInfo.card.settings.isBackupAllowed && cardModel.cardInfo.card.backupStatus == .noBackup
        } else {
            return false
        }
    }

    var tokenItemViewModels: [TokenItemViewModel] {
        guard let cardModel = cardModel,
              let walletModels = cardModel.walletModels else { return [] }

        return walletModels
            .flatMap({ $0.tokenItemViewModels })
    }

    init(cardModel: CardViewModel, coordinator: MainRoutable) {
        self.state = .card(model: cardModel) // [REDACTED_TODO_COMMENT]
        self.coordinator = coordinator
        bind()
        cardModel.updateState()
    }

    deinit {
        print("MainViewModel deinit")
    }

    // MARK: - Functions
    func bind() {
        $state
            .compactMap { $0.cardModel }
            .flatMap { $0.objectWillChange }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                print("⚠️ Card model will change")
                self.objectWillChange.send()
                guard let walletModels = self.cardModel?.walletModels else { return }
                if walletModels.isEmpty {
                    self.totalSumBalanceViewModel.update(with: [])
                } else if !self.isLoadingTokensBalance {
                    self.updateTotalBalanceTokenListIfNeeded()
                }
            }
            .store(in: &bag)

        $state
            .compactMap { $0.cardModel }
            .flatMap { $0.$state }
            .compactMap { $0.walletModels }
            .flatMap { Publishers.MergeMany($0.map { $0.objectWillChange }).collect($0.count) }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                print("⚠️ Wallet model will change")
                self.objectWillChange.send()
            }
            .store(in: &bag)

        $state
            .compactMap { $0.cardModel }
            .flatMap { $0.$state }
            .compactMap { $0.walletModels }
            .flatMap { Publishers.MergeMany($0.map { $0.objectWillChange }).collect($0.count) }
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                if self.isLoadingTokensBalance { return }
                self.updateTotalBalanceTokenListIfNeeded()
                self.objectWillChange.send()
            }
            .store(in: &bag)

        $state
            .compactMap { $0.cardModel }
            .flatMap { $0.imageLoaderPublisher }
            .weakAssignAnimated(to: \.image, on: self)
            .store(in: &bag)

        warningsService.warningsUpdatePublisher
            .sink { [unowned self] (locationUpdate) in
                if case .main = locationUpdate {
                    print("⚠️ Main view model fetching warnings")
                    self.warnings = self.warningsService.warnings(for: .main)
                }
            }
            .store(in: &bag)

        $state
            .compactMap { $0.cardModel }
            .sink { [unowned  self] model in
                print("⚠️ Receive new card model")
                self.selectedAddressIndex = 0
                self.isHashesCounted = false
                self.warningsService.setupWarnings(for: model.cardInfo)
                self.countHashes()
            }
            .store(in: &bag)

        cardModel?
            .$walletsBalanceState
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] state in
                switch state {
                case .inProgress:
                    self.totalSumBalanceViewModel.beginUpdates()
                    self.isLoadingTokensBalance = true
                case .loaded:
                    // Delay for hide skeleton
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.checkPositiveBalance()
                        self.isLoadingTokensBalance = false
                        self.updateTotalBalanceTokenList()
                    }
                }
            }).store(in: &bag)

        $showExplorerURL
            .compactMap { $0 }
            .sink { [unowned self] url in
                self.openExplorer(at: url)
                self.showExplorerURL = nil
            }
            .store(in: &bag)

        $showQR
            .filter { $0 == true }
            .sink { [unowned self] _ in
                self.openQR()
                self.showQR = false
            }
            .store(in: &bag)
    }

    func getDataCollector(for feedbackCase: EmailFeedbackCase) -> EmailDataCollector {
        switch feedbackCase {
        case .negativeFeedback:
            return NegativeFeedbackDataCollector(cardInfo: cardModel!.cardInfo) // [REDACTED_TODO_COMMENT]
        case .scanTroubleshooting:
            return failedCardScanTracker
        }
    }

    func onRefresh(_ done: @escaping () -> Void) {
        if let cardModel = self.cardModel, cardModel.state.canUpdate,
           let walletModels = cardModel.walletModels, !walletModels.isEmpty {
            refreshCancellable = cardModel.refresh()
                .receive(on: RunLoop.main)
                .sink { _ in
                    print("♻️ Wallet model loading state changed")
                    withAnimation {
                        done()
                    }
                } receiveValue: { _ in

                }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    done()
                }
            }
        }
    }

    func updateCardModel() {
        state.cardModel?.update()
            .sink { _ in

            } receiveValue: { _ in

            }
            .store(in: &bag)
    }

    func createWallet() {
        guard let cardModel = cardModel else {
            return
        }

        self.isCreatingWallet = true
        cardModel.createWallet() { [weak self] result in
            defer { self?.isCreatingWallet = false }
            switch result {
            case .success:
                break
            case .failure(let error):
                if case .userCancelled = error.toTangemSdkError() {
                    return
                }
                self?.setError(error.alertBinder)
            }
        }
    }

    func onScan() {
        DispatchQueue.main.async {
            self.totalSumBalanceViewModel.update(with: [])
            self.coordinator.close(newScan: true)
        }
    }

    func sendTapped() {
        guard let wallet = wallets?.first else {
            return
        }

        let hasTokenAmounts = !wallet.amounts.values.filter { $0.type.isToken && !$0.isZero }.isEmpty

        if hasTokenAmounts {
            showSelectWalletSheet.toggle()
        } else {
            openSend(for: Amount(with: wallet.amounts[.coin]!, value: 0))
        }
    }

    func countHashes() {
        guard let card = state.card else {
            return
        }

        if card.firmwareVersion.type == .release {
            validateHashesCount()
        }
    }

    func onAppear() {}

    // MARK: Warning action handler
    func warningButtonAction(at index: Int, priority: WarningPriority, button: WarningButton) {
        guard let warning = warnings.warning(at: index, with: priority) else { return }

        func registerValidatedSignedHashesCard() {
            guard let cardId = state.card?.cardId else {
                return
            }

            AppSettings.shared.validatedSignedHashesCards.append(cardId)
        }

        var hideWarning = true
        // [REDACTED_TODO_COMMENT]
        switch button {
        case .okGotIt:
            if warning.event == .numberOfSignedHashesIncorrect {
                registerValidatedSignedHashesCard()
            }
        case .rateApp:
            Analytics.log(event: .positiveRateAppFeedback)
            rateAppService.userReactToRateAppWarning(isPositive: true)
        case .dismiss:
            Analytics.log(event: .dismissRateAppWarning)
            rateAppService.dismissRateAppWarning()
        case .reportProblem:
            Analytics.log(event: .negativeRateAppFeedback)
            rateAppService.userReactToRateAppWarning(isPositive: false)
            openMail(with: .negativeFeedback)
        case .learnMore:
            if warning.event == .multiWalletSignedHashes {
                error = AlertBinder(alert: Alert(title: Text(warning.title),
                                                 message: Text("alert_signed_hashes_message"),
                                                 primaryButton: .cancel(),
                                                 secondaryButton: .default(Text("alert_button_i_understand")) { [weak self] in
                                                     withAnimation {
                                                         registerValidatedSignedHashesCard()
                                                         self?.warningsService.hideWarning(warning)
                                                     }
                                                 }))
                return
            }
        }

        if hideWarning {
            warningsService.hideWarning(warning)
        }
    }

    func tradeCryptoAction() {
        showTradeSheet.toggle()
    }

    func extractSellCryptoRequest(from response: String) {
        if let request = exchangeService.extractSellCryptoRequest(from: response) {
            openSendToSell(with: request)
        }
    }

    func sendAnalyticsEvent(_ event: Analytics.Event) {
        switch event {
        case .userBoughtCrypto:
            Analytics.log(event: event, with: [.currencyCode: currenyCode])
        default:
            break
        }
    }

    func prepareForBackup() {
        guard let cardModel = cardModel else {
            return
        }
        cardOnboardingStepSetupService
            .backupSteps(cardModel.cardInfo)
            .sink { [weak self] completion in
                guard let self = self else {
                    return
                }
                switch completion {
                case .failure(let error):
                    Analytics.log(error: error)
                    print("Failed to load image for new card")
                    self.error = error.alertBinder
                case .finished:
                    break
                }
            } receiveValue: { [weak self] steps in
                guard let self = self else {
                    return
                }

                let input = OnboardingInput(steps: steps,
                                            cardInput: .cardModel(cardModel),
                                            welcomeStep: nil,
                                            currentStepIndex: 0,
                                            isStandalone: true)

                self.openOnboarding(with: input)
            }
            .store(in: &bag)
    }

    // MARK: - Private functions

    private func checkPositiveBalance() {
        guard rateAppService.shouldCheckBalanceForRateApp else { return }

        guard cardModel?.walletModels?.first(where: { !$0.wallet.isEmpty }) != nil else { return }

        rateAppService.registerPositiveBalanceDate()
    }

    private func validateHashesCount() {
        guard let cardInfo = state.cardModel?.cardInfo else { return }

        let card = cardInfo.card
        guard cardModel?.hasWallet ?? false else {
            cardInfo.isMultiWallet ? warningsService.hideWarning(for: .multiWalletSignedHashes) : warningsService.hideWarning(for: .numberOfSignedHashesIncorrect)
            return
        }

        if isHashesCounted { return }

        if card.isTwinCard { return }

        if card.isDemoCard { return }

        if AppSettings.shared.validatedSignedHashesCards.contains(card.cardId) { return }

        if cardModel?.cardInfo.isMultiWallet ?? false {
            if cardModel?.cardInfo.card.wallets.filter({ $0.totalSignedHashes ?? 0 > 0 }).count ?? 0 > 0 {
                withAnimation {
                    warningsService.appendWarning(for: .multiWalletSignedHashes)
                }
            } else {
                AppSettings.shared.validatedSignedHashesCards.append(card.cardId)
            }
            print("⚠️ Hashes counted")
            return
        }

        func showUntrustedCardAlert() {
            withAnimation {
                self.warningsService.appendWarning(for: .numberOfSignedHashesIncorrect)
            }
        }

        guard
            let numberOfSignedHashes = card.wallets.first?.totalSignedHashes,
            numberOfSignedHashes > 0
        else { return }

        guard
            let validator = cardModel?.walletModels?.first?.walletManager as? SignatureCountValidator
        else {
            showUntrustedCardAlert()
            return
        }

        validator.validateSignatureCount(signedHashes: numberOfSignedHashes)
            .subscribe(on: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .handleEvents(receiveCancel: {
                print("⚠️ Hash counter subscription cancelled")
            })
            .sink(receiveCompletion: { [weak self] failure in
                switch failure {
                case .finished:
                    break
                case .failure:
                    showUntrustedCardAlert()
                }
                self?.isHashesCounted = true
                print("⚠️ Hashes counted")
            }, receiveValue: { _ in })
            .store(in: &bag)
    }

    private func setError(_ error: AlertBinder?)  {
        if self.error != nil {
            return
        }

        self.error = error
        return
    }

    private func updateTotalBalanceTokenList() {
        guard let cardModel = cardModel,
              let walletModels = cardModel.walletModels
        else {
            self.totalSumBalanceViewModel.update(with: [])
            return
        }

        let newTokens = walletModels.flatMap({ $0.tokenItemViewModels })
        totalSumBalanceViewModel.update(with: newTokens)
    }

    private func updateTotalBalanceTokenListIfNeeded() {
        guard let cardModel = cardModel,
              let walletModels = cardModel.walletModels
        else {
            self.totalSumBalanceViewModel.update(with: [])
            return
        }
        let newTokens = walletModels.flatMap({ $0.tokenItemViewModels })
        totalSumBalanceViewModel.updateIfNeeded(with: newTokens)
    }
}

extension MainViewModel {
    enum EmailFeedbackCase: Int, Identifiable {
        case negativeFeedback
        case scanTroubleshooting

        var id: Int { rawValue }

        var emailType: EmailType {
            switch self {
            case .negativeFeedback: return .negativeRateAppFeedback
            case .scanTroubleshooting: return .failedToScanCard
            }
        }
    }
}

// MARK: - Navigation
extension MainViewModel {
    func openSettings() {
        if let cardModel = cardModel {
            coordinator.openSettings(cardModel: cardModel)
        }
    }

    func openTokenDetails(_ tokenItem: TokenItemViewModel) {
        if let cardModel = cardModel {
            coordinator.openTokenDetails(cardModel: cardModel,
                                         blockchainNetwork: tokenItem.blockchainNetwork,
                                         amountType: tokenItem.amountType)
        }
    }

    func openSend(for amountToSend: Amount) {
        guard let cardModel = self.state.cardModel,
              let blockchainNetwork = cardModel.walletModels?.first?.blockchainNetwork else { return }

        coordinator.openSend(amountToSend: amountToSend, blockchainNetwork: blockchainNetwork, cardViewModel: cardModel)
    }

    func openSendToSell(with request: SellCryptoRequest) {
        guard let cardModel = self.state.cardModel,
              let blockchainNetwork = cardModel.walletModels?.first?.blockchainNetwork else { return }

        let amount = Amount(with: blockchainNetwork.blockchain, value: request.amount)
        coordinator.openSendToSell(amountToSend: amount,
                                   destination: request.targetAddress,
                                   blockchainNetwork: blockchainNetwork,
                                   cardViewModel: cardModel)
    }

    func openSellCrypto() {
        if cardModel?.cardInfo.card.isDemoCard ?? false {
            error = AlertBuilder.makeDemoAlert()
            return
        }

        if let url = sellCryptoURL {
            coordinator.openSellCrypto(at: url, sellRequestUrl: sellCryptoCloseUrl) { [weak self] response in
                self?.extractSellCryptoRequest(from: response)
            }
        }
    }

    func openBuyCrypto() {
        guard let cardModel = self.cardModel else { return }

        if cardModel.cardInfo.card.isDemoCard  {
            error = AlertBuilder.makeDemoAlert()
            return
        }

        guard cardModel.cardInfo.isTestnet, !cardModel.cardInfo.isMultiWallet,
              let walletModel = cardModel.walletModels?.first,
              walletModel.wallet.blockchain == .ethereum(testnet: true),
              let token = walletModel.tokenItemViewModels.first?.amountType.token else {
            if let url = buyCryptoURL {
                coordinator.openBuyCrypto(at: url, closeUrl: buyCryptoCloseUrl) { [weak self] _ in
                    self?.sendAnalyticsEvent(.userBoughtCrypto)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self?.updateCardModel()
                    }
                }
            }
            return
        }

        testnetBuyCryptoService.buyCrypto(.erc20Token(token, walletManager: walletModel.walletManager, signer: cardModel.signer))
    }

    func openBuyCryptoIfPossible() {
        if tangemApiService.geoIpRegionCode == "ru" {
            coordinator.openBankWarning {
                self.openBuyCrypto()
            } declineCallback: {
                self.coordinator.openP2PTutorial()
            }
        } else {
            openBuyCrypto()
        }
    }

    func openPushTx(for index: Int) {
        guard let cardModel = self.cardModel,
              let firstWalletModel = cardModel.walletModels?.first else { return }

        let tx = firstWalletModel.wallet.pendingOutgoingTransactions[index]
        coordinator.openPushTx(for: tx, blockchainNetwork: firstWalletModel.blockchainNetwork, card: cardModel)
    }

    func openExplorer(at url: URL) {
        let blockchainName = wallets?.first?.blockchain.displayName ?? ""
        coordinator.openExplorer(at: url, blockchainDisplayName: blockchainName)
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator.openOnboardingModal(with: input)
    }

    func openCurrencySelection() {
        coordinator.openCurrencySelection(autoDismiss: true)
    }

    func openTokensList() {
        if let cardModel = self.cardModel {
            coordinator.openTokensList(with: cardModel)
        }
    }

    func openMail(with emailFeedbackCase: EmailFeedbackCase) {
        let collector = getDataCollector(for: emailFeedbackCase)
        let type = emailFeedbackCase.emailType
        coordinator.openMail(with: collector, emailType: type)
    }

    func openQR() {
        guard let firstWalletModel = cardModel?.walletModels?.first  else { return }

        let shareAddress = firstWalletModel.shareAddressString(for: selectedAddressIndex)
        let address = firstWalletModel.displayAddress(for: selectedAddressIndex)
        let qrNotice = firstWalletModel.getQRReceiveMessage()

        coordinator.openQR(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
    }
}
