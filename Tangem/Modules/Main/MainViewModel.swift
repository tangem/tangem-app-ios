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
    @Injected(\.userWalletListService) private var userWalletListService: UserWalletListService

    // MARK: - Published variables

    @Published var error: AlertBinder?
    @Published var showTradeSheet: Bool = false
    @Published var showSelectWalletSheet: Bool = false
    @Published var isScanning: Bool = false
    @Published var selectedAddressIndex: Int = 0
    @Published var showExplorerURL: URL? = nil
    @Published var showQR: Bool = false
    @Published var isOnboardingModal: Bool = true
    @Published var isLackDerivationWarningViewVisible: Bool = false

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
        isSingleCoinCard: !cardModel.isMultiWallet,
        tapOnCurrencySymbol: openCurrencySelection
    )

    let cardModel: CardViewModel
    let userWalletModel: UserWalletModel?

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

    var image: UIImage? {
        cardModel.cardImage
    }

    init(cardModel: CardViewModel, coordinator: MainRoutable) {
        self.cardModel = cardModel
        self.userWalletModel = cardModel.userWalletModel
        self.coordinator = coordinator
        cardModel.getCardInfo()
        bind()

        cardModel.setupWarnings()
        validateHashesCount()
        userWalletModel?.updateAndReloadWalletModels(showProgressLoading: true)
        showUserWalletSaveIfNeeded()
    }

    deinit {
        print("MainViewModel deinit")
    }

    // MARK: - Functions

    func bind() {
        cardModel.subscribeWalletModels()
            .flatMap { Publishers.MergeMany($0.map { $0.objectWillChange }).collect($0.count) }
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                if self.isLoadingTokensBalance { return }
                self.updateTotalBalanceTokenListIfNeeded()
                self.objectWillChange.send()
            }
            .store(in: &bag)

        cardModel.subscribeToEntriesWithoutDerivation()
            .sink { [unowned self] entries in
                updateLackDerivationWarningView(entries: entries)
            }
            .store(in: &bag)

        warningsService.warningsUpdatePublisher
            .sink { [unowned self] in
                print("⚠️ Main view model fetching warnings")
                self.warnings = self.warningsService.warnings(for: .main)
            }
            .store(in: &bag)

        cardModel
            .$walletsBalanceState
            .dropFirst()
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
            return NegativeFeedbackDataCollector(userWalletEmailData: cardModel.emailData)
        case .scanTroubleshooting:
            return failedCardScanTracker
        }
    }

    func updateWalletTokenListViewModel() {
        guard let userWalletModel = cardModel.userWalletModel else {
            assertionFailure("User Wallet Model not created")
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
        walletTokenListViewModel?.refreshTokens { result in
            print("♻️ Wallet model loading state changed with result", result)
            withAnimation {
                done()
            }
        }
    }

    func onScan() {
        if AppSettings.shared.saveUserWallets {
            self.coordinator.openUserWalletList()
        } else {
            DispatchQueue.main.async {
                Analytics.log(.scanCardTapped)
                self.totalSumBalanceViewModel.update(with: [])
                self.coordinator.close(newScan: true)
            }
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
        walletTokenListViewModel?.onAppear()
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

    private func checkPositiveBalance() {
        guard rateAppService.shouldCheckBalanceForRateApp else { return }

        guard cardModel.walletModels.first(where: { !$0.wallet.isEmpty }) != nil else { return }

        rateAppService.registerPositiveBalanceDate()
    }

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

    private func updateTotalBalanceTokenList() {
        let newTokens = cardModel.walletModels.flatMap({ $0.tokenItemViewModels })
        totalSumBalanceViewModel.update(with: newTokens)
    }

    private func updateTotalBalanceTokenListIfNeeded() {
        let newTokens = cardModel.walletModels.flatMap({ $0.tokenItemViewModels })
        totalSumBalanceViewModel.updateIfNeeded(with: newTokens)
    }

    private func updateLackDerivationWarningView(entries: [StorageEntry]) {
        isLackDerivationWarningViewVisible = !entries.isEmpty
    }

    private func showUserWalletSaveIfNeeded() {
        if AppSettings.shared.askedToSaveUserWallets || !BiometricsUtil.isAvailable {
            return
        }

        AppSettings.shared.askedToSaveUserWallets = true

        let delay = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.coordinator.openUserWalletSaveAcceptanceSheet()
        }
    }

    func didDeclineToSaveUserWallets() {
        AppSettings.shared.saveUserWallets = false
    }

    func didAgreeToSaveUserWallets() {
        userWalletListService.unlockWithBiometry { [weak self, cardModel] result in
            if case let .failure(error) = result {
                print("Failed to enable biometry: \(error)")
                return
            }

            // Doesn't seem to work without the delay
            let delay = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let _ = self?.userWalletListService.save(cardModel.userWallet)
                self?.coordinator.openUserWalletList()
                AppSettings.shared.saveUserWallets = true
                AppSettings.shared.saveAccessCodes = true
            }
        }
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
                    self.userWalletModel?.updateAndReloadWalletModels(showProgressLoading: true)
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
