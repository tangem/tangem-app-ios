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

struct CardOnboardingInput {
    let steps: OnboardingSteps
    let cardModel: CardViewModel
    var currentStepIndex: Int
    let cardImage: UIImage
    var successCallback: (() -> Void)?
}

class SingleCardOnboardingViewModel: ViewModel {
    
    weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    
    weak var cardsRepository: CardsRepository!
    weak var stepsSetupService: OnboardingStepsSetupService!
    weak var userPrefsService: UserPrefsService!
    weak var exchangeService: ExchangeService!
    weak var imageLoaderService: CardImageLoaderService!
    
    @Published var steps: [NoteOnboardingStep] =
        []
//        [.read, .createWallet, .topup, .confetti]
    @Published var executingRequestOnCard = false
    @Published var currentStepIndex: Int = 0
    @Published var cardImage: UIImage? = UIImage(named: "card_btc")
    @Published var shouldFireConfetti: Bool = false
    @Published var refreshButtonState: OnboardingCircleButton.State = .refreshButton
    @Published var cardBalance: String = "0.00001237893 ETH"
    @Published var isAddressQrBottomSheetPresented: Bool = false
    
    var numberOfProgressBarSteps: Int {
        steps.filter { $0.hasProgressStep }.count
    }
    
    var shopURL: URL { Constants.shopURL }
    
    var currentStep: NoteOnboardingStep {
        guard currentStepIndex < steps.count else {
            return .read
        }
        
        return steps[currentStepIndex]
    }
    
    var shareAddress: String {
        scannedCardModel?.walletModels?.first?.shareAddressString(for: 0) ?? ""
    }
    
    var walletAddress: String {
        scannedCardModel?.walletModels?.first?.displayAddress(for: 0) ?? ""
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
    private var previewUpdateCounter: Int = 0
    
    private var isFromMain: Bool = false
    private var walletCreatedWhileOnboarding: Bool = false
    
    private var scannedCardModel: CardViewModel?
    private var walletModelUpdateCancellable: AnyCancellable?
    private var scheduledUpdate: DispatchWorkItem?
    
    private var successCallback: (() -> Void)?
    
    
    init() {}
    
    init(input: CardOnboardingInput) {
        if case let .singleWallet(steps) = input.steps {
            self.steps = steps
        } else {
            fatalError("Wrong onboarding steps passed to initializer")
        }
        
        scannedCardModel = input.cardModel
        currentStepIndex = input.currentStepIndex
        cardImage = input.cardImage
        successCallback = input.successCallback
        isFromMain = true
        updateCardBalance()
    }
        
    // MARK: Functions

    func goToNextStep() {
        let nextStepIndex = currentStepIndex + 1
        
        func goToMain() {
            if isFromMain {
                successCallback?()
            } else if !assembly.isPreview {
                assembly.getCardOnboardingViewModel().toMain = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.userPrefsService.isTermsOfServiceAccepted = true
                self.reset()
            }
        }
        
        guard !steps.isEmpty, nextStepIndex < steps.count else {
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
        // [REDACTED_TODO_COMMENT]
        walletModelUpdateCancellable = nil
        
        withAnimation {
            navigation.onboardingReset = true
            scannedCardModel = nil
            currentStepIndex = 0
            steps = []
            executingRequestOnCard = false
            refreshButtonState = .refreshButton
            cardBalance = ""
            previewUpdateCounter = 0
        }
    }
    
    func executeStep() {
        switch currentStep {
        case .read:
            if userPrefsService.isTermsOfServiceAccepted || assembly.isPreview {
                
            } else {
                showDisclaimer()
            }
        case .createWallet:
            сreateWallet()
        case .topup:
            navigation.onboardingToBuyCrypto = true
        case .confetti:
            if assembly.isPreview {
                reset()
            }
        default:
            break
        }
    }
    
    
    func showDisclaimer() {
        navigation.onboardingToDisclaimer = true
    }
    
    func acceptDisclaimer() {
        userPrefsService.isTermsOfServiceAccepted = true
        navigation.onboardingToDisclaimer = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            
        }
        
    }
    
    func updateCardBalance() {
        guard
            let walletModel = scannedCardModel?.walletModels?.first,
            walletModelUpdateCancellable == nil
        else { return }
        
        if (assembly?.isPreview) ?? false {
            previewUpdateCounter += 1
            
            if previewUpdateCounter >= 3 {
                scannedCardModel = Assembly.PreviewCard.scanResult(for: .cardanoNote, assembly: assembly).cardModel
            }
        }
        scheduledUpdate?.cancel()
        refreshButtonState = .activityIndicator
        walletModelUpdateCancellable = walletModel.$state
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] walletModelState in
                self?.updateCardBalanceText(for: walletModel)
                switch walletModelState {
                case .noAccount(let message):
                    print(message)
                    fallthrough
                case .idle:
                    if !walletModel.isEmptyIncludingPendingIncomingTxs {
                        self?.goToNextStep()
                        return
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
            }
        walletModel.update(silent: false)
    }
    
    private func сreateWallet() {
        guard let cardModel = scannedCardModel else {
            return
        }
        
        executingRequestOnCard = true
        
        if assembly.isPreview {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.scannedCardModel = Assembly.PreviewCard.scanResult(for: .cardanoNoteEmptyWallet, assembly: self.assembly).cardModel!
                self.updateCardBalanceText(for: self.scannedCardModel!.walletModels!.first!)
                self.executingRequestOnCard = false
                self.goToNextStep()
            }
            return
        }
        
        let card = cardModel.cardInfo.card
        
        cardModel.createWallet { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.walletCreatedWhileOnboarding = true
                if card.isTangemNote {
                    self.userPrefsService.cardsStartedActivation.append(card.cardId)
                }
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
    
    private func updateCardBalanceText(for model: WalletModel) {
        withAnimation {
            cardBalance = model.getBalance(for: .coin)
        }
    }
    
    private func topupNote() {
        
    }
    
}
