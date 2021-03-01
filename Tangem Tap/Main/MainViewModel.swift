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
            return state.cardModel?.canCreateTwinCard ?? false
        }
        
        if let state = state.cardModel?.state,
           case .empty = state {
            return true
        }
        
        return false
    }
    
    var canTopup: Bool {
        return state.cardModel?.canTopup ?? false
    }
    
    var topupURL: URL? {
        if let wallet = state.wallet {
            return topupService.getTopupURL(currencySymbol: wallet.blockchain.currencySymbol,
                                     walletAddress: wallet.address)
        }
        return nil
    }
    
    var topupCloseUrl: String {
        return topupService.topupCloseUrl.removeLatestSlash()
    }
    
    public var canSend: Bool {
        guard let model = state.cardModel else {
            return false
        }
        
        guard model.canSign else {
            return false
        }
        
        guard let wallet = state.wallet else {
            return false
        }
        
        if wallet.hasPendingTx {
            return false
        }
        
        if wallet.amounts.isEmpty { //not loaded from blockchain
            return false
        }
        
        if wallet.amounts.values.first(where: { $0.value > 0 }) == nil { //empty wallet
            return false
        }
        
        let coinAmount = wallet.amounts[.coin]?.value ?? 0
        if coinAmount <= 0 { //not enough fee
            return false
        }
        
        return true
    }
    
    var incomingTransactions: [BlockchainSdk.Transaction] {
        guard let wallet = state.wallet else {
            return []
        }
        
        return wallet.transactions.filter { $0.destinationAddress == wallet.address
            && $0.status == .unconfirmed
            && $0.sourceAddress != "unknown"
        }
    }
    
    var outgoingTransactions: [BlockchainSdk.Transaction] {
        guard let wallet = state.wallet else {
            return []
        }
        
        return wallet.transactions.filter { $0.sourceAddress == wallet.address
            && $0.status == .unconfirmed
            && $0.destinationAddress != "unknown"
        }
    }
	
	var cardNumber: Int? {
		state.cardModel?.cardInfo.twinCardInfo?.series?.number
	}
	
	var isTwinCard: Bool {
		state.cardModel?.isTwinCard ?? false
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
            .compactMap { $0.walletModel }
            .flatMap { $0.objectWillChange }
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                print("⚠️ Wallet model will change")
                self.objectWillChange.send()
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
        
        $state
            .compactMap { $0.cardModel }
            .flatMap { $0.$state }
            .compactMap { $0.walletModel }
            .flatMap { $0.$state }
            .map { $0.isLoading }
            .filter { !$0 }
            .receive(on: RunLoop.main)
            .sink {[unowned self] isRefreshing in
                print("♻️ Wallet model loading state changed")
                withAnimation {
                    self.isRefreshing = isRefreshing
                }
            }
            .store(in: &bag)
        
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
        
        $state
            .compactMap { $0.cardModel?.cardInfo }
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
                if let cardModel = self.state.cardModel, cardModel.state.canUpdate {
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
        guard let cardModel = state.cardModel else {
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
        guard let wallet = state.wallet else {
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
    
    // MARK: - Private functions
	
	private func validateHashesCount() {
        guard let card = state.card else { return }
        
        guard state.cardModel?.hasWallet ?? false else {
            warningsManager.hideWarning(for: .numberOfSignedHashesIncorrect)
            return
        }
        
        if isHashesCounted { return }
        
		if card.isTwinCard { return }
		
		guard let cardId = card.cardId else { return }
		
		if validatedSignedHashesCards.contains(cardId) { return }
		
		func showUntrustedCardAlert() {
            withAnimation {
                self.warningsManager.addWarning(for: .numberOfSignedHashesIncorrect)
            }
		}
        
        guard
            let numberOfSignedHashes = card.walletSignedHashes,
            numberOfSignedHashes > 0
        else { return }
		
		guard
			let validator = state.cardModel?.state.walletModel?.walletManager as? SignatureCountValidator
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
		guard let model = state.cardModel, model.isTwinCard else { return false }
		
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
