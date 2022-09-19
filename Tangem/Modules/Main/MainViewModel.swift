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
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Published variables

    @Published var error: AlertBinder?
    @Published var showTradeSheet: Bool = false
    @Published var showSelectWalletSheet: Bool = false
    @Published var isScanning: Bool = false
    @Published var image: UIImage? = nil
    @Published var selectedAddressIndex: Int = 0
    @Published var showExplorerURL: URL? = nil
    @Published var showQR: Bool = false
    @Published var isOnboardingModal: Bool = true
    @Published var isLackDerivationWarningViewVisible: Bool = false
    @Published var singleWalletModel: WalletModel? = nil

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

    var walletTokenListViewModel: WalletTokenListViewModel?

    // MARK: Variables
    var isLoadingTokensBalance: Bool = false

    lazy var totalSumBalanceViewModel = TotalSumBalanceViewModel(
        userWalletModel: userWalletModel,
        totalBalanceManager: TotalBalanceProvider(userWalletModel: userWalletModel),
        isSingleCoinCard: !cardModel.isMultiWallet,
        tapOnCurrencySymbol: openCurrencySelection
    )

    var cardSetLabel: String? { cardModel.cardSetLabel }

    private let cardModel: CardViewModel
    private let userWalletModel: UserWalletModel

    private var bag = Set<AnyCancellable>()
    private var isHashesCounted = false
    private var isProcessingNewCard = false

    private lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()

    private unowned let coordinator: MainRoutable

    public var canSend: Bool {
        guard cardModel.canSend else {
            return false
        }

        guard let wallet = wallets?.first else {
            return false
        }

        return wallet.canSend(amountType: .coin)
    }

    var wallets: [Wallet]? {
        cardModel.wallets
    }

    var currenyCode: String {
        wallets?.first?.blockchain.currencySymbol ?? .unknown
    }

    var canBuyCrypto: Bool {
        cardModel.canExchangeCrypto && buyCryptoURL != nil
    }

    var canSellCrypto: Bool {
        cardModel.canExchangeCrypto && sellCryptoURL != nil
    }

    var cardsCountLabel: String? {
        cardModel.cardSetLabel
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
        cardModel.walletModels.first?.incomingPendingTransactions ?? []
    }

    var outgoingTransactions: [PendingTransaction] {
        cardModel.walletModels.first?.outgoingPendingTransactions ?? []
    }

    var isBackupAllowed: Bool {
        cardModel.canCreateBackup
    }

    var tokenListIsEmpty: Bool {
        walletTokenListViewModel?.contentState.isEmpty ?? true
    }

    var isMultiWalletMode: Bool {
        cardModel.isMultiWallet
    }

    var canShowAddress: Bool {
        cardModel.canShowAddress
    }

    var canShowSend: Bool {
        cardModel.canShowSend
    }

    init(cardModel: CardViewModel, userWalletModel: UserWalletModel, coordinator: MainRoutable) {
        self.cardModel = cardModel
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator

        // [REDACTED_TODO_COMMENT]
        // separate on two ViewModels for multi and single wallet
        bind()
        bindSingleWallet()

        cardModel.setupWarnings()
        validateHashesCount()
        updateWalletTokenListViewModel()
    }

    deinit {
        print("MainViewModel deinit")
    }

    // MARK: - Functions

    func bind() {
        cardModel.subscribeToEntriesWithoutDerivation()
            .sink { [unowned self] entries in
                updateLackDerivationWarningView(entries: entries)
            }
            .store(in: &bag)

        cardModel
            .imageLoaderPublisher
            .weakAssignAnimated(to: \.image, on: self)
            .store(in: &bag)

        warningsService.warningsUpdatePublisher
            .sink { [unowned self] in
                print("⚠️ Main view model fetching warnings")
                self.warnings = self.warningsService.warnings(for: .main)
            }
            .store(in: &bag)


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

    func bindSingleWallet() {
        guard !isMultiWalletMode else { return }

        userWalletModel.subscribeToWalletModels()
            .map { walletModels in
                walletModels
                    .map { $0.objectWillChange }
                    .combineLatest()
                    .map { _ in walletModels }
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] walletModels in
                singleWalletModel = walletModels.first
            }
            .store(in: &bag)
    }

    func getDataCollector(for feedbackCase: EmailFeedbackCase) -> EmailDataCollector {
        switch feedbackCase {
        case .negativeFeedback:
            return NegativeFeedbackDataCollector(userWalletEmailData: cardModel.emailData)
        case .scanTroubleshooting:
            return failedCardScanTracker
        }
    }

    func updateWalletTokenListViewModel() {
        guard cardModel.isMultiWallet else {
            return
        }

        walletTokenListViewModel = WalletTokenListViewModel(
            userTokenListManager: userWalletModel.userTokenListManager,
            userWalletModel: userWalletModel
        ) { [weak self] itemViewModel in
            self?.openTokenDetails(itemViewModel)
        }
    }

    func onRefresh(_ done: @escaping () -> Void) {
        Analytics.log(.mainPageRefresh)
        if cardModel.isMultiWallet {
            walletTokenListViewModel?.refreshTokens {
                print("♻️ RefreshTokens success")
                withAnimation {
                    done()
                }
            }
        } else {
            userWalletModel.updateAndReloadWalletModels(completion: done)
        }
    }

    func onScan() {
        DispatchQueue.main.async {
            Analytics.log(.scanCardTapped)
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

    func onAppear() {
        if cardModel.isMultiWallet {
            walletTokenListViewModel?.onAppear()
        } else {
            userWalletModel.updateAndReloadWalletModels()
        }
    }

    func deriveEntriesWithoutDerivation() {
        cardModel.deriveEntriesWithoutDerivation()
    }

    // MARK: Warning action handler
    func warningButtonAction(at index: Int, priority: WarningPriority, button: WarningButton) {
        guard let warning = warnings.warning(at: index, with: priority) else { return }

        func registerValidatedSignedHashesCard() {
            AppSettings.shared.validatedSignedHashesCards.append(cardModel.cardId)
        }

        // [REDACTED_TODO_COMMENT]
        switch button {
        case .okGotIt:
            if case .numberOfSignedHashesIncorrect = warning.event {
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
            if case .multiWalletSignedHashes = warning.event {
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

        warningsService.hideWarning(warning)
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
        if let input = cardModel.backupInput {
            self.openOnboarding(with: input)
        }
    }

    func copyAddress() {
        Analytics.log(.copyAddressTapped)
        if let walletModel = cardModel.walletModels.first {
            UIPasteboard.general.string = walletModel.displayAddress(for: selectedAddressIndex)
        }
    }

    // MARK: - Private functions

    private func validateHashesCount() {
        guard cardModel.canCountHashes else { return }

        guard cardModel.hasWallet else {
            if cardModel.isMultiWallet {
                warningsService.hideWarning(for: .multiWalletSignedHashes)
            } else {
                warningsService.hideWarning(for: .numberOfSignedHashesIncorrect)
            }
            return
        }

        if isHashesCounted { return }

        if AppSettings.shared.validatedSignedHashesCards.contains(cardModel.cardId) { return }

        if cardModel.isMultiWallet {
            if cardModel.cardSignedHashes > 0 {
                withAnimation {
                    warningsService.appendWarning(for: .multiWalletSignedHashes)
                }
            } else {
                AppSettings.shared.validatedSignedHashesCards.append(cardModel.cardId)
            }
            print("⚠️ Hashes counted")
            return
        }

        func showUntrustedCardAlert() {
            withAnimation {
                self.warningsService.appendWarning(for: .numberOfSignedHashesIncorrect)
            }
        }

        guard cardModel.cardSignedHashes > 0 else { return }

        guard let validator = cardModel.walletModels.first?.walletManager as? SignatureCountValidator else {
            showUntrustedCardAlert()
            return
        }

        validator.validateSignatureCount(signedHashes: cardModel.cardSignedHashes)
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

    private func updateLackDerivationWarningView(entries: [StorageEntry]) {
        isLackDerivationWarningViewVisible = !entries.isEmpty
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
        coordinator.openSettings(cardModel: cardModel)
    }

    func openTokenDetails(_ tokenItem: TokenItemViewModel) {
        coordinator.openTokenDetails(cardModel: cardModel,
                                     blockchainNetwork: tokenItem.blockchainNetwork,
                                     amountType: tokenItem.amountType)
    }

    func openSend(for amountToSend: Amount) {
        guard let blockchainNetwork = cardModel.walletModels.first?.blockchainNetwork else { return }

        coordinator.openSend(amountToSend: amountToSend, blockchainNetwork: blockchainNetwork, cardViewModel: cardModel)
    }

    func openSendToSell(with request: SellCryptoRequest) {
        guard let blockchainNetwork = cardModel.walletModels.first?.blockchainNetwork else { return }

        let amount = Amount(with: blockchainNetwork.blockchain, value: request.amount)
        coordinator.openSendToSell(amountToSend: amount,
                                   destination: request.targetAddress,
                                   blockchainNetwork: blockchainNetwork,
                                   cardViewModel: cardModel)
    }

    func openSellCrypto() {
        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if let url = sellCryptoURL {
            coordinator.openSellCrypto(at: url, sellRequestUrl: sellCryptoCloseUrl) { [weak self] response in
                self?.extractSellCryptoRequest(from: response)
            }
        }
    }

    func openBuyCrypto() {
        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if let walletModel = cardModel.walletModels.first,
           walletModel.wallet.blockchain == .ethereum(testnet: true),
           let token = walletModel.wallet.amounts.keys.compactMap({ $0.token }).first {
            testnetBuyCryptoService.buyCrypto(.erc20Token(token, walletManager: walletModel.walletManager, signer: cardModel.signer))
        }

        if let url = buyCryptoURL {
            coordinator.openBuyCrypto(at: url, closeUrl: buyCryptoCloseUrl) { [weak self] _ in
                guard let self = self else { return }

                self.sendAnalyticsEvent(.userBoughtCrypto)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.userWalletModel.updateAndReloadWalletModels()
                }
            }
        }
    }

    func openBuyCryptoIfPossible() {
        Analytics.log(.buyTokenTapped)
        if tangemApiService.geoIpRegionCode == LanguageCode.ru {
            coordinator.openBankWarning {
                Analytics.log(.p2pInstructionTapped, params: [.type: "yes"])
                self.openBuyCrypto()
            } declineCallback: {
                Analytics.log(.p2pInstructionTapped, params: [.type: "no"])
                self.coordinator.openP2PTutorial()
            }
        } else {
            openBuyCrypto()
        }
    }

    func openPushTx(for index: Int) {
        guard let firstWalletModel = cardModel.walletModels.first else { return }

        let tx = firstWalletModel.wallet.pendingOutgoingTransactions[index]
        coordinator.openPushTx(for: tx, blockchainNetwork: firstWalletModel.blockchainNetwork, card: cardModel)
    }

    func openExplorer(at url: URL) {
        Analytics.log(.exploreAddressTapped)
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
        coordinator.openTokensList(with: cardModel)
    }

    func openMail(with emailFeedbackCase: EmailFeedbackCase) {
        let collector = getDataCollector(for: emailFeedbackCase)
        let type = emailFeedbackCase.emailType
        coordinator.openMail(with: collector, emailType: type, recipient: cardModel.emailConfig.recipient)
    }

    func openQR() {
        guard let firstWalletModel = cardModel.walletModels.first  else { return }

        let shareAddress = firstWalletModel.shareAddressString(for: selectedAddressIndex)
        let address = firstWalletModel.displayAddress(for: selectedAddressIndex)
        let qrNotice = firstWalletModel.getQRReceiveMessage()

        coordinator.openQR(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
    }
}
