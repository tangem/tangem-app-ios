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
    
    
    @Published var steps: [OnboardingStep] =
        []
//        [.read, .createWallet, .topup]
    @Published var executingRequestOnCard = false
    @Published var currentStepIndex: Int = 0
    
    var previewUpdatePublisher: PassthroughSubject<Void, Never> = PassthroughSubject<Void, Never>()
    
    var shopURL: URL { Constants.shopURL }
    
    private var bag: Set<AnyCancellable> = []
    private var scannedCardModel: CardViewModel?
    
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

    func goToNextStep() {
        let nextStepIndex = currentStepIndex + 1
        
        guard nextStepIndex < steps.count else { return }
        
        if steps[nextStepIndex] == .goToMain  {
            navigation.readToMain = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.reset()
            }
            return
        }
        withAnimation {
            self.currentStepIndex = nextStepIndex
        }
    }
    
    func reset() {
        scannedCardModel = nil
        currentStepIndex = 0
        steps = []
    }
    
    func executeStep() {
        switch currentStep {
        case .read:
            scanCard()
        case .disclaimer:
            userPrefsService.isTermsOfServiceAccepted = true
            goToNextStep()
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
            processScannedCard(previewModel.cardInfo.card)
            previewUpdatePublisher.send()
            return
        }
        
        cardsRepository.scan { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success(let result):
                guard let card = result.card else { return }
                
                self.scannedCardModel = result.cardModel
                self.processScannedCard(card)
                self.executingRequestOnCard = false
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func updateCardBalance() {
        guard let cardModel = scannedCardModel else { return }
        
        cardModel.walletModels?.forEach {
            $0.update()
        }
    }
    
    private func processScannedCard(_ card: Card) {
        stepsSetupService.steps(for: card)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    print(error)
                }
                self.executingRequestOnCard = false
            } receiveValue: { [weak self] steps in
                guard let self = self else { return }
                
                withAnimation {
                    self.steps = steps
                    self.goToNextStep()
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
        let card = cardModel.cardInfo.card
        if card.isTangemNote {
//            userPrefsService.noteCardsStartedActivation.append(card.cardId)
        }
        
        cardModel.createWallet { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.executingRequestOnCard = false
                self.goToNextStep()
            }
        }
    }
    
    private func topupNote() {
        
    }
    
}
