//
//  MainViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk
import TangemSdk

class MainViewModel: ViewModel, ObservableObject {
    // MARK: Dependencies -
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.appWarningsService) private var warningsService: AppWarningsProviding
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable
    @Injected(\.rateAppService) private var rateAppService: RateAppService
    @Injected(\.onboardingStepsSetupService) private var cardOnboardingStepSetupService: OnboardingStepsSetupService
    @Injected(\.negativeFeedbackDataProvider) var negativeFeedbackDataCollector: NegativeFeedbackDataProvider
    @Injected(\.geoIpService) private var geoIpService: GeoIpService
    
    //MARK: - Published variables
    @Published var showBankWarning: Bool = false
    @Published var showP2PTutorial: Bool = false
    @Published var error: AlertBinder?
    @Published var isScanning: Bool = false
    @Published var isCreatingWallet: Bool = false
    @Published var image: UIImage? = nil
    @Published var selectedAddressIndex: Int = 0
    @Published var showExplorerURL: URL? = nil
    @Published var showExternalURL: URL? = nil
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
    @Published var emailFeedbackCase: EmailFeedbackCase? = nil
    @Published var txIndexToPush: Int? = nil
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
    
    var amountToSend: Amount? = nil
    var selectedWallet: TokenItemViewModel = .default
    var sellCryptoRequest: SellCryptoRequest? = nil
    var isLoadingTokensBalance: Bool = false
    lazy var totalSumBalanceViewModel: TotalSumBalanceViewModel = assembly.makeTotalSumBalanceViewModel()
    
	@Storage(type: .validatedSignedHashesCards, defaultValue: [])
	private var validatedSignedHashesCards: [String]
    private var userPrefsService: UserPrefsService = .init()
    private var bag = Set<AnyCancellable>()
    private var isHashesCounted = false
    private var isProcessingNewCard = false
    private var refreshCancellable: AnyCancellable? = nil
    private lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()
    
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
    
    var transactionToPush: BlockchainSdk.Transaction? {
        guard let index = txIndexToPush else { return nil }
        
        return cardModel?.walletModels?.first?.wallet.pendingOutgoingTransactions[index]
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
    
    var tokenItemViewModels: [TokenItemViewModel] {
        guard let cardModel = cardModel,
              let walletModels = cardModel.walletModels else { return [] }
        
        return walletModels
            .flatMap ({ $0.tokenItemViewModels })
    }
    
    var qrMessage: String {
        return self.cardModel?.walletModels?.first?.getQRReceiveMessage() ?? ""
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
            .sink {[unowned  self] model in
                print("⚠️ Receive new card model")
                self.selectedAddressIndex = 0
                self.isHashesCounted = false
                self.assembly.reset()
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
                    //Delay for hide skeleton
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.checkPositiveBalance()
                        self.isLoadingTokensBalance = false
                        self.updateTotalBalanceTokenList()
                    }
                }
            }).store(in: &bag)
    }
    
    func updateState() {
        self.state = cardsRepository.lastScanResult
    }
    
    func getDataCollector(for feedbackCase: EmailFeedbackCase) -> EmailDataCollector {
        switch feedbackCase {
        case .negativeFeedback:
            return negativeFeedbackDataCollector
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
        
		if cardModel.isTwinCard {
            if cardModel.hasBalance {
                error = AlertBinder(alert: Alert(title: Text("Attention!"),
                                                 message: Text("Your wallet is not empty, please withdraw your funds before creating twin wallet or they will be lost."),
                                                 primaryButton: .cancel(),
                                                 secondaryButton: .destructive(Text("I understand, continue anyway")) { [weak self] in
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                        self?.prepareTwinOnboarding()
                                                    }
                                                 }))
            } else {
                prepareTwinOnboarding()
            }
		} else {
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
    }
    
    func onScan() {
        DispatchQueue.main.async {
            self.assembly.getLetsStartOnboardingViewModel()?.reset()
            self.assembly.getLaunchOnboardingViewModel().reset()
            self.totalSumBalanceViewModel.update(with: [])
            self.navigation.popToRoot()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.assembly.getLetsStartOnboardingViewModel()?.scanCard()
            }
        }
    }
    
    func sendTapped() {
        guard let wallet = wallets?.first else {
            return
        }
        
        let hasTokenAmounts = !wallet.amounts.values.filter { $0.type.isToken && !$0.isZero }.isEmpty
        
        if hasTokenAmounts {
            navigation.mainToSendChoise = true
        } else {
            amountToSend = Amount(with: wallet.amounts[.coin]!, value: 0)
            showSendScreen() 
        }
    }
    
    func showSendScreen() {
        assembly.reset()
        sellCryptoRequest = nil
        navigation.mainToSend = true
    }
    
    func countHashes() {
        guard let card = state.card else {
            return
        }
        
        if card.firmwareVersion.type == .release {
            validateHashesCount()
        }
    }
    
    func onAppear() {
        assembly.reset()
    }
    
    // MARK: Warning action handler
    func warningButtonAction(at index: Int, priority: WarningPriority, button: WarningButton) {
        guard let warning = warnings.warning(at: index, with: priority) else { return }

        func registerValidatedSignedHashesCard() {
            guard let cardId = state.card?.cardId else {
                return
            }
            
            validatedSignedHashesCards.append(cardId)
        }
        
        var hideWarning = true
        //TODO: refactoring
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
            
            if warning.event == .fundsRestoration {
                userPrefsService.isFundsRestorationShown = true
            }
            
        case .reportProblem:
            Analytics.log(event: .negativeRateAppFeedback)
            rateAppService.userReactToRateAppWarning(isPositive: false)
            emailFeedbackCase = .negativeFeedback
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
            } else if warning.event == .fundsRestoration {
                hideWarning = false
                
                let fundRestorationUrl: URL
                switch Locale.current.languageCode {
                case "ru":
                    fundRestorationUrl = URL(string: "https://tangem.com/ru/kak-vosstanovit-tokeny-otpravlennye-ne-na-tot-adres-v-tangem-wallet")!
                default:
                    fundRestorationUrl = URL(string: "https://tangem.com/en/how-to-recover-crypto-sent-to-the-wrong-address-in-tangem-wallet")!
                }
                showExternalURL = fundRestorationUrl
            }
        }
        
        if hideWarning {
            warningsService.hideWarning(warning)
        }
    }
    
    func onWalletTap(_ tokenItem: TokenItemViewModel) {
        selectedWallet = tokenItem
        assembly.reset()
        navigation.mainToTokenDetails = true
    }
    
    func buyCryptoAction() {
        guard let cardInfo = cardModel?.cardInfo else { return }
        
        if cardInfo.card.isDemoCard  {
            error = AlertBuilder.makeDemoAlert()
            return
        }
        
        guard cardInfo.isTestnet, !cardInfo.isMultiWallet,
            let walletModel = cardModel?.walletModels?.first,
            walletModel.wallet.blockchain == .ethereum(testnet: true),
            let token = walletModel.tokenItemViewModels.first?.amountType.token else {
            if buyCryptoURL != nil {
                navigation.mainToBuyCrypto = true
            }
            return
        }
        
        testnetBuyCryptoService.buyCrypto(.erc20Token(walletManager: walletModel.walletManager, token: token))
    }
    
    func buyCryptoIfPossible() {
        if geoIpService.regionCode == "ru" {
            showBankWarning = true
        } else {
            buyCryptoAction()
        }
    }
    
    func showP2PTutorialAction() {
        showP2PTutorial = true
    }
    
    func tradeCryptoAction() {
        navigation.mainToTradeSheet = true
    }
    
    func sellCryptoAction() {
        if cardModel?.cardInfo.card.isDemoCard ?? false {
            error = AlertBuilder.makeDemoAlert()
            return
        }
        
        navigation.mainToSellCrypto = true
    }
    
    func extractSellCryptoRequest(from response: String) {
        guard let request = exchangeService.extractSellCryptoRequest(from: response) else {
            return
        }
        
        sellCryptoRequest = request
        resetViewModel(of: SendViewModel.self)
        navigation.mainToSend = true
    }
    
    func pushOutgoingTx(at index: Int) {
        resetViewModel(of: PushTxViewModel.self)
        txIndexToPush = index
    }
    
    func sendAnalyticsEvent(_ event: Analytics.Event) {
        switch event {
        case .userBoughtCrypto:
            Analytics.log(event: event, with: [.currencyCode: currenyCode])
        default:
            break
        }
    }
    
    func onboardingDismissed() {
        
    }
    
    func prepareTwinOnboarding() {
        guard let cardModel = self.cardModel else { return }

        cardOnboardingStepSetupService.twinRecreationSteps(for: cardModel.cardInfo)
            .sink { completion in
            switch completion {
            case .failure(let error):
                Analytics.log(error: error)
                print("Failed to load image for new card")
                self.error = error.alertBinder
            case .finished:
                break
            }
        } receiveValue: { [weak self] steps in
            guard let self = self else { return }

            let input = OnboardingInput(steps: steps,
                                        cardInput: .cardModel(cardModel),
                                        cardsPosition: nil,
                                        welcomeStep: nil,
                                        currentStepIndex: 0,
                                        successCallback: { [weak self] in
                                            self?.navigation.mainToCardOnboarding = false
                                        })
            self.assembly.makeCardOnboardingViewModel(with: input)
            self.navigation.mainToCardOnboarding = true
        }
        .store(in: &bag)
    }
    
    func showCurrencyChangeScreen() {
        navigation.currencyChangeView = true
    }

    // MARK: - Private functions
    
//    private func processScannedCard(_ result: ScanResult) {
//        func updateState() {
//            state = result
//            isScanning = false
//            navigation.mainToCardOnboarding = false
//            isProcessingNewCard = false
//            isOnboardingModal = false
//        }
//
//        guard
//            let cardModel = result.cardModel
////            cardsRepository.scannedCardsRepository.cards[cardModel.cardInfo.card.cardId] == nil
//        else {
//            updateState()
//            return
//        }
//
//        isProcessingNewCard = true
//
//        cardOnboardingStepSetupService
//            .stepsWithCardImage(for: cardModel)
//            .sink { completion in
//                switch completion {
//                case .failure(let error):
//                    Analytics.log(error: error)
//                    print("Failed to load image for new card")
//                    self.isScanning = false
//                    self.error = error.alertBinder
//                case .finished:
//                    break
//                }
//            } receiveValue: { [weak self] (steps, image) in
//                guard let self = self else { return }
//
//                guard steps.needOnboarding else {
//                    updateState()
//                    return
//                }
//
//                let input = OnboardingInput(steps: steps,
//                                                cardModel: cardModel,
//                                                cardImage: image,
//                                                cardsPosition: nil,
//                                                welcomeStep: nil,
//                                                currentStepIndex: 0,
//                                                successCallback: updateState)
//                self.assembly.makeCardOnboardingViewModel(with: input)
//                self.navigation.mainToCardOnboarding = true
//                self.isScanning = false
//            }
//            .store(in: &bag)
//    }
    
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

        if validatedSignedHashesCards.contains(card.cardId) { return }
        
        if cardModel?.cardInfo.isMultiWallet ?? false {
            if cardModel?.cardInfo.card.wallets.filter({ $0.totalSignedHashes ?? 0 > 0 }).count ?? 0 > 0 {
                withAnimation {
                    warningsService.appendWarning(for: .multiWalletSignedHashes)
                }
            } else {
                validatedSignedHashesCards.append(card.cardId)
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
    
    private func resetViewModel<T>(of typeToReset: T) {
        assembly.reset(key: String(describing: type(of: typeToReset)))
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
        var id: Int { rawValue }
        
        case negativeFeedback, scanTroubleshooting
        
        var emailType: EmailType {
            switch self {
            case .negativeFeedback: return .negativeRateAppFeedback
            case .scanTroubleshooting: return .failedToScanCard
            }
        }
    }
}
