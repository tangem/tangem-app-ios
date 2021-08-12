//
//  OnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import Combine

class OnboardingViewModel: ViewModel {
    
    weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    
    weak var cardsRepository: CardsRepository!
    weak var stepsSetupService: OnboardingStepsSetupService!
    weak var userPrefsService: UserPrefsService!
    weak var exchangeService: ExchangeService!
    weak var imageLoaderService: CardImageLoaderService!
    
    @Published var steps: [OnboardingStep] =
        []
//        [.read, .createWallet, .topup, .confetti, .goToMain]
    @Published var executingRequestOnCard = false
    @Published var currentStepIndex: Int = 0
    @Published var cardImage: UIImage? = UIImage(named: "card_btc")
    @Published var shouldFireConfetti: Bool = false
    @Published var refreshButtonState: OnboardingCircleButton.State = .refreshButton
    @Published var isDisclaimer: Bool = false
    
    var shopURL: URL { Constants.shopURL }
    
    var cardBalance: String {
        scannedCardModel?.walletModels?.first?.getBalance(for: .coin) ?? ""
    }
    
    var currentStep: OnboardingStep {
        guard currentStepIndex < steps.count else {
            return .read
        }
        
        return steps[currentStepIndex]
    }
    
    var isExchangeServiceAvailable: Bool { exchangeService.canBuyCrypto }
    
    var buyCryptoURL: URL? {
        if let wallet = scannedCardModel?.wallets?.first {
            return exchangeService.getBuyUrl(currencySymbol: wallet.blockchain.currencySymbol,
                                             walletAddress: wallet.address)
        }
        return nil
    }
    
    var buyCryptoCloseUrl: String { exchangeService.successCloseUrl.removeLatestSlash() }
    
    private var bag: Set<AnyCancellable> = []
    private var scannedCardModel: CardViewModel?
    private var walletCreatedWhileOnboarding: Bool = false
    
    // MARK: Functions

    func goToNextStep() {
        let nextStepIndex = currentStepIndex + 1
        
        func goToMain() {
            navigation.readToMain = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.reset()
            }
        }
        
        guard nextStepIndex < steps.count else {
            goToMain()
            return
        }
        
        if steps[nextStepIndex] == .goToMain  {
            goToMain()
            return
        }
        withAnimation {
            self.currentStepIndex = nextStepIndex
        }
        
        stepUpdate()
    }
    
    func reset() {
        scannedCardModel = nil
        currentStepIndex = 0
        steps = []
        executingRequestOnCard = false
        refreshButtonState = .refreshButton
    }
    
    func executeStep() {
        switch currentStep {
        case .read:
            scanCard()
        case .createWallet:
            сreateWallet()
        case .topup:
            navigation.onboardingToBuyCrypto = true
        default:
            break
        }
    }
    
    func scanCard() {
        executingRequestOnCard = true
        if assembly.isPreview {
            executingRequestOnCard = false
            let previewModel = assembly.previewCardViewModel
            self.scannedCardModel = previewModel
            processScannedCard(previewModel)
            return
        }
        
        cardsRepository.scan { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success(let result):
                guard let cardModel = result.cardModel else { return }
                
                self.scannedCardModel = cardModel
                self.processScannedCard(cardModel)
            case .failure(let error):
                print(error)
            }
            self.executingRequestOnCard = false
        }
    }
    
    func acceptDisclaimer() {
        userPrefsService.isTermsOfServiceAccepted = true
        navigation.onboardingToDisclaimer = false
    }
    
    private var walletModelUpdateCancellable: AnyCancellable?
    func updateCardBalance() {
        guard
            let walletModel = scannedCardModel?.walletModels?.first,
            walletModelUpdateCancellable == nil
        else { return }
        
        refreshButtonState = .activityIndicator
        walletModelUpdateCancellable = walletModel.$state
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] walletModelState in
                switch walletModelState {
                case .noAccount(let message):
                    print(message)
                    fallthrough
                case .idle:
                    if !walletModel.wallet.isEmpty {
                        self?.goToNextStep()
                        break
                    }
                    withAnimation {
                        self?.refreshButtonState = .refreshButton
                    }
                case .failed(let error):
                    print(error)
                    withAnimation {
                        self?.refreshButtonState = .refreshButton
                    }
                case .loading, .created:
                    return
                }
                self?.walletModelUpdateCancellable = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                    self?.updateCardBalance()
                }
            }
        walletModel.update(silent: false)
    }
    
    private func processScannedCard(_ cardModel: CardViewModel) {
        stepsSetupService.steps(for: cardModel.cardInfo.card)
            .flatMap { steps -> AnyPublisher<([OnboardingStep], UIImage?), Error> in
                if steps.count > 2 && !self.assembly.isPreview {
                    return cardModel.$cardInfo
                        .filter {
                            $0.artwork != .notLoaded
                        }
                        .map { $0.imageLoadDTO }
                        .removeDuplicates()
                        .setFailureType(to: Error.self)
                        .flatMap { [unowned self] info in
                            self.imageLoaderService
                                .loadImage(cid: info.cardId,
                                           cardPublicKey: info.cardPublicKey,
                                           artworkInfo: info.artwotkInfo)
                        }
                        .replaceError(with: UIImage())
                        .map { (steps, $0) }
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else {
                    return .justWithError(output: (steps, nil))
                        
                }
            }
            .receive(on: DispatchQueue.main)
            .map { [weak self] (steps, image) -> [OnboardingStep] in
                self?.cardImage = (self?.assembly.isPreview ?? false) ? UIImage(named: "card_btc") : image
                return steps
            }
            .sink { completion in
                if case let .failure(error) = completion {
                    print(error)
                    self.executingRequestOnCard = false
                }
            } receiveValue: { [weak self] steps in
                guard let self = self else { return }
                
                withAnimation {
                    self.steps = steps
                    if !self.userPrefsService.isTermsOfServiceAccepted {
                        self.navigation.onboardingToDisclaimer = true
                    } else {
                        self.goToNextStep()
                    }
                    self.executingRequestOnCard = false
                }
            }
            .store(in: &bag)

    }
    
    private func сreateWallet() {
        guard let cardModel = scannedCardModel else {
            return
        }
        
        executingRequestOnCard = true
        
        
        if assembly.isPreview {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.executingRequestOnCard = false
                self.goToNextStep()
            }
            return
        }
        
        let card = cardModel.cardInfo.card
        if card.isTangemNote {
//            userPrefsService.noteCardsStartedActivation.append(card.cardId)
        }
        
        cardModel.createWallet { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.walletCreatedWhileOnboarding = true
            case .failure(let error):
                print(error)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.executingRequestOnCard = false
                self.goToNextStep()
            }
        }
    }
    
    private func stepUpdate() {
        switch currentStep {
        case .topup:
            if walletCreatedWhileOnboarding {
                return
            }
            
            updateCardBalance()
        case .confetti:
            withAnimation {
                refreshButtonState = .doneCheckmark
            }
            shouldFireConfetti = true
        default:
            break
        }
    }
    
    private func topupNote() {
        
    }
    
}
