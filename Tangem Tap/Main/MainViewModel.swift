//
//  MainViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk
import TangemSdk

class MainViewModel: ViewModel, ObservableObject {
    // MARK: Dependencies -
    weak var imageLoaderService: CardImageLoaderService!
    weak var exchangeService: ExchangeService!
	weak var userPrefsService: UserPrefsService!
    weak var cardsRepository: CardsRepository!
    weak var warningsManager: WarningsManager!
    weak var rateAppController: RateAppController!
	weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    weak var negativeFeedbackDataCollector: NegativeFeedbackDataCollector!
    weak var failedCardScanTracker: FailedCardScanTracker!
    weak var cardOnboardingStepSetupService: OnboardingStepsSetupService!
    
    //MARK: - Published variables
    
    @Published var isRefreshing = false
    @Published var error: AlertBinder?
    @Published var isScanning: Bool = false
    @Published var isCreatingWallet: Bool = false
    @Published var image: UIImage? = nil
    @Published var selectedAddressIndex: Int = 0
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
    
	@Storage(type: .validatedSignedHashesCards, defaultValue: [])
	private var validatedSignedHashesCards: [String]
    
    private var bag = Set<AnyCancellable>()
    private var isHashesCounted = false
    private var isProcessingNewCard = false
    
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
                return URL(string: blockchain.testnetBuyCryptoLink ?? "")
            }
            
            return exchangeService.getBuyUrl(currencySymbol: wallet.blockchain.currencySymbol,
                                          walletAddress: wallet.address)
        }
        return nil
    }
    
    var sellCryptoURL: URL? {
        if let wallet = wallets?.first {
            return exchangeService.getSellUrl(currencySymbol: wallet.blockchain.currencySymbol, walletAddress: wallet.address)
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
		cardModel?.cardInfo.twinCardInfo?.series.number
	}
	
	var isTwinCard: Bool {
		cardModel?.isTwinCard ?? false
	}
    
    var tokenItemViewModels: [TokenItemViewModel] {
        guard let cardModel = cardModel,
              let walletModels = cardModel.walletModels else { return [] }
        
        return walletModels
            .flatMap ({ $0.tokenItemViewModels })
            .sorted(by: { lhs, rhs in
                if lhs.blockchain == cardModel.cardInfo.defaultBlockchain && rhs.blockchain == cardModel.cardInfo.defaultBlockchain {
                    if lhs.amountType.isToken && rhs.amountType.isToken {
                        if lhs.amountType.token == cardModel.cardInfo.defaultToken {
                            return true
                        }

                        if rhs.amountType.token == cardModel.cardInfo.defaultToken {
                            return false
                        }
                    }

                    if !lhs.amountType.isToken {
                        return true
                    }

                    if !rhs.amountType.isToken {
                        return false
                    }
                }

                if lhs.blockchain == cardModel.cardInfo.defaultBlockchain {
                   return true
                }

                if rhs.blockchain == cardModel.cardInfo.defaultBlockchain {
                    return false
                }

                return lhs < rhs
            })
    }
    
    deinit {
        print("MainViewModel deinit")
    }
    
    // MARK: - Functions
    func bind() {
        $state
            .compactMap { $0.cardModel }
            .flatMap {$0.objectWillChange }
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                print("⚠️ Card model will change")
                self.objectWillChange.send()
            }
            .store(in: &bag)
        
        $state
            .compactMap { $0.cardModel }
            .flatMap { $0.$state }
            .compactMap { $0.walletModels }
            .flatMap { Publishers.MergeMany($0.map { $0.objectWillChange.debounce(for: 0.3, scheduler: DispatchQueue.main) }) }
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                print("⚠️ Wallet model will change")
                self.objectWillChange.send()
                self.checkPositiveBalance()
            }
            .store(in: &bag)
    
        
        $state
            .compactMap { $0.cardModel }
            .setFailureType(to: Error.self)
            .flatMap { $0.imageLoaderPublisher }
            .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        Analytics.log(error: error)
                        print(error.localizedDescription)
                    case .finished:
                        break
                    }}){ [unowned self] image in
                print(image)
                self.image = image
            }
            .store(in: &bag)
        
//        $state
//            .compactMap { $0.cardModel }
//            .receive(on: RunLoop.main)
//            .sink { [unowned self] model in
//                print("⚠️ Card model updated")
//                assembly.services.warningsService.setupWarnings(for: model.cardInfo)
//            }
//            .store(in: &bag)
        
        warningsManager.warningsUpdatePublisher
            .sink { [unowned self] (locationUpdate) in
                if case .main = locationUpdate {
                    print("⚠️ Main view model fetching warnings")
                    self.warnings = self.warningsManager.warnings(for: .main)
                }
            }
            .store(in: &bag)
        
        $state
            .compactMap { $0.cardModel }
            .flatMap { $0.$state }
            .compactMap { $0.walletModels }
            .flatMap { Publishers.MergeMany($0.map { $0.$state.map{ $0.isLoading }.filter { !$0 } }).collect($0.count) }
            .delay(for: 1, scheduler: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .sink {[unowned self] _ in
                print("♻️ Wallet model loading state changed")
                withAnimation {
                    self.isRefreshing = false
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
                self.assembly.services.warningsService.setupWarnings(for: model.cardInfo)
//                if !self.showTwinCardOnboardingIfNeeded() {
                    self.countHashes()
//                }
            }
            .store(in: &bag)
        
        $isRefreshing
            .removeDuplicates()
            .filter { $0 }
            .sink{ [unowned self] _ in
                if let cardModel = self.cardModel, cardModel.state.canUpdate, cardModel.walletModels?.count ?? 0 > 0 {
                    cardModel.update()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            self.isRefreshing = false
                        }
                    }
                }
                
            }
            .store(in: &bag)
    }
    
    // MARK: - Scan
    func scan() {
        self.isScanning = true
        cardsRepository.scan { [weak self] scanResult in
			guard let self = self else { return }
            switch scanResult {
            case .success(let result):
                self.processScannedCard(result)
                self.failedCardScanTracker.resetCounter()
            case .failure(let error):
                self.failedCardScanTracker.recordFailure()
                
                if self.failedCardScanTracker.shouldDisplayAlert {
                    self.navigation.mainToTroubleshootingScan = true
                } else {
                    switch error.toTangemSdkError() {
                    case .unknownError, .cardVerificationFailed:
                        self.setError(error.alertBinder)
                    default:
                        break
                    }
                }
                self.isScanning = false
            }
            
        }
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
    
    func sendTapped() {
        guard let wallet = wallets?.first else {
            return
        }
        
        let hasTokenAmounts = wallet.amounts.values.filter { $0.type.isToken && !$0.isEmpty }.count > 0
        
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
        
        switch button {
        case .okGotIt:
            if warning.event == .numberOfSignedHashesIncorrect {
                registerValidatedSignedHashesCard()
            }
        case .rateApp:
            Analytics.log(event: .positiveRateAppFeedback)
            rateAppController.userReactToRateAppWarning(isPositive: true)
        case .dismiss:
            Analytics.log(event: .dismissRateAppWarning)
            rateAppController.dismissRateAppWarning()
        case .reportProblem:
            Analytics.log(event: .negativeRateAppFeedback)
            rateAppController.userReactToRateAppWarning(isPositive: false)
            emailFeedbackCase = .negativeFeedback
        case .learnMore:
            if warning.event == .multiWalletSignedHashes {
                error = AlertBinder(alert: Alert(title: Text(warning.title),
                                                 message: Text("alert_signed_hashes_message"),
                                                 primaryButton: .cancel(),
                                                 secondaryButton: .default(Text("alert_button_i_understand")) { [weak self] in
                                                    withAnimation {
                                                        registerValidatedSignedHashesCard()
                                                        self?.warningsManager.hideWarning(warning)
                                                    }
                                                 }))
                return
            }
        }
        warningsManager.hideWarning(warning)
    }
    
    func onWalletTap(_ tokenItem: TokenItemViewModel) {
        selectedWallet = tokenItem
        assembly.reset()
        navigation.mainToTokenDetails = true
    }
    
    func buyCryptoAction() {
        guard let cardInfo = cardModel?.cardInfo else { return }
        
        guard
            cardInfo.isTestnet,
            !cardInfo.isMultiWallet,
            let walletModel = cardModel?.walletModels?.first,
            let token = walletModel.tokenItemViewModels.first?.amountType.token,
            case .ethereum(testnet: true) = token.blockchain
        else {
            if buyCryptoURL != nil {
                navigation.mainToBuyCrypto = true
            }
            return
        }
        
        TestnetBuyCryptoService.buyCrypto(.erc20Token(walletManager: walletModel.walletManager, token: token))
    }
    
    func sellCryptoAction() {
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
        
        cardOnboardingStepSetupService!.twinRecreationSteps(for: cardModel.cardInfo)
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
                                        cardModel: cardModel,
                                        cardImage:  self.image,
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

    // MARK: - Private functions
    
    private func processScannedCard(_ result: ScanResult) {
        func updateState() {
            state = result
            isScanning = false
            navigation.mainToCardOnboarding = false
            isProcessingNewCard = false
            isOnboardingModal = false
        }
        
        guard
            let cardModel = result.cardModel
//            cardsRepository.scannedCardsRepository.cards[cardModel.cardInfo.card.cardId] == nil
        else {
            updateState()
            return
        }
        
        isProcessingNewCard = true
        
        cardOnboardingStepSetupService
            .stepsWithCardImage(for: cardModel)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    Analytics.log(error: error)
                    print("Failed to load image for new card")
                    self.isScanning = false
                    self.error = error.alertBinder
                case .finished:
                    break
                }
            } receiveValue: { [weak self] (steps, image) in
                guard let self = self else { return }
                
                guard steps.needOnboarding else {
                    updateState()
                    return
                }
                
                let input = OnboardingInput(steps: steps,
                                                cardModel: cardModel,
                                                cardImage: image,
                                                cardsPosition: nil,
                                                welcomeStep: nil,
                                                currentStepIndex: 0,
                                                successCallback: updateState)
                self.assembly.makeCardOnboardingViewModel(with: input)
                self.navigation.mainToCardOnboarding = true
                self.isScanning = false
            }
            .store(in: &bag)
    }
    
    private func checkPositiveBalance() {
        guard rateAppController.shouldCheckBalanceForRateApp else { return }
        
        guard cardModel?.walletModels?.first(where: { !$0.wallet.isEmpty }) != nil else { return }
        
        rateAppController.registerPositiveBalanceDate()
    }
	
	private func validateHashesCount() {
        guard let cardInfo = state.cardModel?.cardInfo else { return }
        
        let card = cardInfo.card
        guard cardModel?.hasWallet ?? false else {
            cardInfo.isMultiWallet ? warningsManager.hideWarning(for: .multiWalletSignedHashes) : warningsManager.hideWarning(for: .numberOfSignedHashesIncorrect)
            return
        }
        
        if isHashesCounted { return }
        
        if card.isTwinCard { return }

        if validatedSignedHashesCards.contains(card.cardId) { return }
        
        if cardModel?.isMultiWallet ?? false {
            if cardModel?.cardInfo.card.wallets.filter({ $0.totalSignedHashes ?? 0 > 0 }).count ?? 0 > 0 {
                withAnimation {
                    warningsManager.appendWarning(for: .multiWalletSignedHashes)
                }
            } else {
                validatedSignedHashesCards.append(card.cardId)
            }
            print("⚠️ Hashes counted")
            return
        }
		
		func showUntrustedCardAlert() {
            withAnimation {
                self.warningsManager.appendWarning(for: .numberOfSignedHashesIncorrect)
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
		
//	private func showTwinCardOnboardingIfNeeded() -> Bool {
//		guard let model = cardModel, model.isTwinCard else { return false }
//
//		if userPrefsService.isTwinCardOnboardingWasDisplayed { return false }
//
//		navigation.mainToTwinOnboarding = true
//		return true
//	}
    
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
