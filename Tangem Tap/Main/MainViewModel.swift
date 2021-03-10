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

class MainViewModel: ViewModel {
    
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
    
    // MARK: Dependencies -
    weak var imageLoaderService: ImageLoaderService!
    weak var topupService: TopupService!
	weak var userPrefsService: UserPrefsService!
    weak var cardsRepository: CardsRepository!
    weak var warningsManager: WarningsManager!
    weak var rateAppController: RateAppController!
    
	weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    
    var negativeFeedbackDataCollector: NegativeFeedbackDataCollector!
    var failedCardScanTracker: FailedCardScanTracker!
    
    // MARK: Variables
    
    var amountToSend: Amount? = nil
    private var bag = Set<AnyCancellable>()
    @Published var isRefreshing = false
    
    var selectedWallet: TokenItemViewModel = .default
    //MARK: - Output
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
	
	@Storage(type: .validatedSignedHashesCards, defaultValue: [])
	private var validatedSignedHashesCards: [String]
    
    private var isHashesCounted = false
    
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
    
    var cardModel: CardViewModel? {
        return state.cardModel
    }
    
    var wallets: [Wallet]? {
        return cardModel?.wallets
    }
    
    var canTopup: Bool {
        return cardModel?.canTopup ?? false
    }
    
    var topupURL: URL? {
        if let wallet = wallets?.first {
            return topupService.getTopupURL(currencySymbol: wallet.blockchain.currencySymbol,
                                     walletAddress: wallet.address)
        }
        return nil
    }
    
    var topupCloseUrl: String {
        return topupService.topupCloseUrl.removeLatestSlash()
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
        
        return wallet.canSend
    }
    
    var incomingTransactions: [BlockchainSdk.Transaction] {
        wallets?.first?.incomingTransactions ?? []
    }
    
    var outgoingTransactions: [BlockchainSdk.Transaction] {
        wallets?.first?.outgoingTransactions ?? []
    }
	
	var cardNumber: Int? {
		cardModel?.cardInfo.twinCardInfo?.series?.number
	}
	
	var isTwinCard: Bool {
		cardModel?.isTwinCard ?? false
	}
    
    var tokenItemViewModels: [TokenItemViewModel]? {
        guard let cardModel = cardModel else { return nil }
        
        return cardModel.walletModels?
            .flatMap ({ $0.tokenItemViewModels })
            .sorted(by: { lhs, rhs in
                if lhs.blockchain == cardModel.cardInfo.card.blockchain && rhs.blockchain == cardModel.cardInfo.card.blockchain {
                    if lhs.amountType.isToken && rhs.amountType.isToken {
                        if lhs.amountType.token == cardModel.cardInfo.card.token {
                            return true
                        }
                        
                        if rhs.amountType.token == cardModel.cardInfo.card.token {
                            return false
                        }
                        
                        if lhs.fiatBalance != " " && rhs.fiatBalance != " " && lhs.fiatBalance != rhs.fiatBalance {
                            return lhs.fiatBalance > rhs.fiatBalance
                        }
                        
                        return lhs.name < rhs.name
                    }
                    
                    if !lhs.amountType.isToken {
                        return true
                    }
                    
                    if !rhs.amountType.isToken {
                        return false
                    }
                }
                
                if lhs.blockchain == cardModel.cardInfo.card.blockchain {
                   return true
                }
                
                if rhs.blockchain == cardModel.cardInfo.card.blockchain {
                    return false
                }
                
                if lhs.fiatBalance != " " && rhs.fiatBalance != " " && lhs.fiatBalance != rhs.fiatBalance {
                    return lhs.fiatBalance > rhs.fiatBalance
                }
                
                return lhs.name < rhs.name
            })
    }
    
    // MARK: - Functions
    func bind() {
        $state
            .compactMap { $0.cardModel }
            .flatMap {$0.objectWillChange }
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                print("‼️ Card model will change")
                self.objectWillChange.send()
            }
            .store(in: &bag)
        
        $state
            .compactMap { $0.cardModel }
            .flatMap { $0.$state }
            .compactMap { $0.walletModels }
            .flatMap { Publishers.MergeMany($0.map { $0.objectWillChange}) }
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                print("⚠️ Wallet model will change")
                self.objectWillChange.send()
                self.checkPositiveBalance()
            }
            .store(in: &bag)
        
        $state
            .compactMap { $0.cardModel }
            .flatMap { $0.$state }
            .receive(on: RunLoop.main)
            .sink { [unowned self] state in
                print("🌀 Card model state updated")
                self.fetchWarnings()
            }
            .store(in: &bag)
        
        
        if let loadingPublishers = cardModel?.walletModels?.map ({
            $0.$state
                .map{ $0.isLoading }
                .filter { !$0 }
        }) {
            Publishers.MergeMany(loadingPublishers)
                .collect(loadingPublishers.count)
                .delay(for: 1, scheduler: DispatchQueue.global())
                .receive(on: RunLoop.main)
                .sink {[unowned self] _ in
                    print("♻️ Wallet model loading state changed")
                    withAnimation {
                        self.isRefreshing = false
                    }
                }
                .store(in: &bag)
        }
    
        $state
            .filter { $0.cardModel != nil }
            .sink {[unowned  self] _ in
                print("✅ Receive new card model")
                self.selectedAddressIndex = 0
                self.isHashesCounted = false
                self.assembly.reset()
                if !self.showTwinCardOnboardingIfNeeded() {
                    self.showUntrustedDisclaimerIfNeeded()
                }
            }
            .store(in: &bag)
        
        state.cardModel?.$cardInfo
            .tryMap { cardInfo -> (String, Data, ArtworkInfo?) in
                if let cid = cardInfo.card.cardId,
                   let key = cardInfo.card.cardPublicKey  {
                    return (cid, key, cardInfo.artworkInfo)
                }
                
                throw "Some error"
            }
            .flatMap {[unowned self] info in
                return self.imageLoaderService
                    .loadImage(cid: info.0,
                               cardPublicKey: info.1,
                               artworkInfo: info.2)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        Analytics.log(error: error)
                        print(error.localizedDescription)
                    case .finished:
                        break
                    }}){ [unowned self] image in
                self.image = image
            }
            .store(in: &bag)
        
        $isRefreshing
            .removeDuplicates()
            .filter { $0 }
            .sink{ [unowned self] _ in
                if let cardModel = self.cardModel, cardModel.state.canUpdate {
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
    
    // MARK: Scan
    func scan() {
        self.isScanning = true
        cardsRepository.scan { [weak self] scanResult in
			guard let self = self else { return }
            switch scanResult {
            case .success(let state):
                self.state = state
                self.failedCardScanTracker.resetCounter()
            case .failure(let error):
                self.failedCardScanTracker.recordFailure()
                
                if self.failedCardScanTracker.shouldDisplayAlert {
                    self.navigation.mainToTroubleshootingScan = true
                } else {
                    if case .unknownError = error.toTangemSdkError() {
                        self.setError(error.alertBinder)
                    }
                }
            }
            self.isScanning = false
        }
    }
    
    func fetchWarnings() {
        print("⚠️ Main view model fetching warnings")
        self.warnings = self.warningsManager.warnings(for: .main)
    }
    
    func createWallet() {
        guard let cardModel = cardModel else {
            return
        }
		
		if cardModel.isTwinCard {
			navigation.mainToTwinsWalletWarning = true
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
        navigation.mainToSend = true
    }
    
    func showUntrustedDisclaimerIfNeeded() {
        guard let card = state.card else {
            return
        }
        
        if card.cardType == .release {
            validateHashesCount()
        }
    }
    
    func onAppear() {
        assembly.reset()
    }
    
    // MARK: Warning action handler
    func warningButtonAction(at index: Int, priority: WarningPriority, button: WarningButton) {
        guard let warning = warnings.warning(at: index, with: priority) else { return }

        switch button {
        case .okGotIt:
            if let cardId = state.card?.cardId,
               case .numberOfSignedHashesIncorrect = warning.event {
                validatedSignedHashesCards.append(cardId)
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
        }
        warningsManager.hideWarning(warning)
    }
    
    func  onWalletTap(_ tokenItem: TokenItemViewModel) {
        selectedWallet = tokenItem
        assembly.reset()
        navigation.mainToTokenDetails = true
    }

    // MARK: - Private functions
    
    private func checkPositiveBalance() {
        guard rateAppController.shouldCheckBalanceForRateApp else { return }
        
        guard cardModel?.walletModels?.first(where: { !$0.wallet.isEmpty }) != nil else { return }
        
        rateAppController.registerPositiveBalanceDate()
    }
	
	private func validateHashesCount() {
        guard let card = state.card else { return }
        
        guard !(cardModel?.isMultiWallet ?? false) else { return }
        
        guard cardModel?.hasWallet ?? false else {
            warningsManager.hideWarning(for: .numberOfSignedHashesIncorrect)
            return
        }
        
        if isHashesCounted { return }
        
		if card.isTwinCard { return }
		
		guard let cardId = card.cardId else { return }
		
		if validatedSignedHashesCards.contains(cardId) { return }
		
		func showUntrustedCardAlert() {
            withAnimation {
                self.warningsManager.appendWarning(for: .numberOfSignedHashesIncorrect)
            }
		}
        
        guard
            let numberOfSignedHashes = card.walletSignedHashes,
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
		
	private func showTwinCardOnboardingIfNeeded() -> Bool {
		guard let model = cardModel, model.isTwinCard else { return false }
		
		if userPrefsService.isTwinCardOnboardingWasDisplayed { return false }
		
		navigation.mainToTwinOnboarding = true
		return true
	}
    
    private func setError(_ error: AlertBinder?)  {
        if self.error != nil {
            return
        }

        self.error = error
        return
    }
}
