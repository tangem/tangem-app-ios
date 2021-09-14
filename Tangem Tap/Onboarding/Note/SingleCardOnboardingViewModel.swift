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
    let cardImage: UIImage
    let cardsPosition: (dark: AnimatedViewSettings, light: AnimatedViewSettings)?
    let welcomeStep: WelcomeStep?
    
    var currentStepIndex: Int
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
    
    let navbarSize: CGSize = .init(width: UIScreen.main.bounds.width, height: 44)
    
    @Published var steps: [SingleCardOnboardingStep] =
        []
//        [.createWallet, .topup, .confetti]
    @Published var executingRequestOnCard = false
    @Published var currentStepIndex: Int = 0
    @Published var cardImage: UIImage?
    @Published var shouldFireConfetti: Bool = false
    @Published var refreshButtonState: OnboardingCircleButton.State = .refreshButton
    @Published var cardBalance: String = "0.0"
    @Published var isAddressQrBottomSheetPresented: Bool = false
    @Published var cardAnimSettings: AnimatedViewSettings = .zero
    @Published var lightCardAnimSettings: AnimatedViewSettings = .zero
    @Published private(set) var isInitialAnimPlayed = false
    
    private(set) var numberOfSteps: Int
    
    var currentProgress: CGFloat {
        CGFloat(currentStep.progressStep) / CGFloat(numberOfSteps)
    }
    
    var numberOfProgressBarSteps: Int {
        steps.filter { $0.hasProgressStep }.count
    }
    
    var shopURL: URL { Constants.shopURL }
    
    var currentStep: SingleCardOnboardingStep {
        guard currentStepIndex < steps.count else {
            return .topup
        }
        
        return steps[currentStepIndex]
    }
    
    var title: LocalizedStringKey {
        if !isInitialAnimPlayed, let welcomeStep = input.welcomeStep {
            return welcomeStep.title
        }
        
        return currentStep.title
    }
    
    var subtitle: LocalizedStringKey {
        if !isInitialAnimPlayed, let welcomteStep = input.welcomeStep {
            return welcomteStep.subtitle
        }
        
        return currentStep.subtitle
    }
    
    var mainButtonTitle: LocalizedStringKey {
        if !isInitialAnimPlayed, let welcomeStep = input.welcomeStep {
            return welcomeStep.mainButtonTitle
        }
        
        return currentStep.primaryButtonTitle
    }
    
    var supplementButtonTitle: LocalizedStringKey {
        if !isInitialAnimPlayed, let welcomteStep = input.welcomeStep {
            return welcomteStep.supplementButtonTitle
        }
        
        return currentStep.secondaryButtonTitle
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
    
    private let input: CardOnboardingInput
    
    private var bag: Set<AnyCancellable> = []
    private var previewUpdateCounter: Int = 0
    private var containerSize: CGSize = .zero
    
    private var isFromMain: Bool = false
    private var walletCreatedWhileOnboarding: Bool = false
    
    private var scannedCardModel: CardViewModel?
    private var walletModelUpdateCancellable: AnyCancellable?
    private var scheduledUpdate: DispatchWorkItem?
    
    private var successCallback: (() -> Void)?
    
    init(input: CardOnboardingInput) {
        if case let .singleWallet(steps) = input.steps {
            self.steps = steps
        } else {
            fatalError("Wrong onboarding steps passed to initializer")
        }
        
        self.input = input
        scannedCardModel = input.cardModel
        currentStepIndex = input.currentStepIndex
        cardImage = input.cardImage
        successCallback = input.successCallback
        numberOfSteps = SingleCardOnboardingStep.maxNumberOfSteps(isNote: input.cardModel.cardInfo.card.isTangemNote)
        if let cardsPos = input.cardsPosition {
            cardAnimSettings = cardsPos.dark
            lightCardAnimSettings = cardsPos.light
            isFromMain = false
        } else {
            isFromMain = true
        }
        
        if let walletModel = input.cardModel.walletModels?.first {
            updateCardBalanceText(for: walletModel)
        }
        updateCardBalance()
    }
        
    // MARK: Functions
    
    func setupContainer(with size: CGSize) {
        let isInitialSetup = containerSize == .zero
        containerSize = size
        if input.welcomeStep != nil, isInitialAnimPlayed {
            setupCard(animated: !isInitialSetup)
        }
        
    }
    
    func playInitialAnim() {
        let animated = !isFromMain
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(animated ? .default : nil) {
                self.isInitialAnimPlayed = true
                self.setupCard(animated: animated)
            }
        }
        
    }

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
            setupCard(animated: true)
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
            setupCard(animated: true)
            steps = []
            executingRequestOnCard = false
            refreshButtonState = .refreshButton
            cardBalance = ""
            previewUpdateCounter = 0
        }
    }
    
    func executeStep() {
        switch currentStep {
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
        cardBalance = model.getBalance(for: .coin)
    }
    
    private func readPreviewCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let previewModel = Assembly.PreviewCard.scanResult(for: .ethEmptyNote, assembly: self.assembly).cardModel!
            self.scannedCardModel = previewModel
            self.stepsSetupService.steps(for: previewModel.cardInfo)
                .sink { _ in }
                    receiveValue: { steps in
                        if case let .singleWallet(singleSteps) = steps {
                            self.steps = singleSteps
                        }
                        self.goToNextStep()
                        self.executingRequestOnCard = false
                }
                .store(in: &self.bag)

        }
    }
    
    private func setupCard(animated: Bool) {
        cardAnimSettings = .init(targetSettings: SingleCardOnboardingCardsLayout.main.cardAnimSettings(for: currentStep,
                                                                                  containerSize: containerSize,
                                                                                  animated: animated),
                                 intermediateSettings: nil)
        lightCardAnimSettings = .init(targetSettings: SingleCardOnboardingCardsLayout.supplementary.cardAnimSettings(for: currentStep, containerSize: containerSize, animated: animated), intermediateSettings: nil)
    }
    
}
