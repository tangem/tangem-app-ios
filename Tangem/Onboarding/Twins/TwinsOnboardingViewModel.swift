//
//  TwinsOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class TwinsOnboardingViewModel: OnboardingTopupViewModel<TwinsOnboardingStep>, ObservableObject {
    unowned var twinsService: TwinsWalletCreationService
    unowned var imageLoaderService: CardImageLoaderService
    
    @Published var firstTwinImage: UIImage?
    @Published var secondTwinImage: UIImage?
    @Published var pairNumber: String
    @Published var currentCardIndex: Int = 0
    @Published var displayTwinImages: Bool = false
    @Published var alertAccepted: Bool = false
    
    var retwinMode: Bool = false
    
    override var currentStep: TwinsOnboardingStep {
        guard currentStepIndex < steps.count else {
            return assembly.isPreview ? .intro(pairNumber: pairNumber) : .welcome
        }
        
        guard isInitialAnimPlayed else {
            return .welcome
        }

        return steps[currentStepIndex]
    }
    
    override var title: LocalizedStringKey {
        if !isInitialAnimPlayed {
            return super.title
        }
        
        if twinInfo.series.number != 1 {
            switch currentStep {
            case .first, .third:
                return TwinsOnboardingStep.second.title
            case .second:
                return TwinsOnboardingStep.first.title
            default:
                break
            }
        }
        
        return super.title
    }
        
    override var mainButtonTitle: LocalizedStringKey {
        if !isInitialAnimPlayed {
            return super.mainButtonTitle
        }
        
        if twinInfo.series.number != 1 {
            switch currentStep {
            case .first, .third:
                return TwinsOnboardingStep.second.mainButtonTitle
            case .second:
                return TwinsOnboardingStep.first.mainButtonTitle
            default:
                break
            }
        }
        
        if case .topup = currentStep, !canBuy {
            return "onboarding_button_receive_crypto"
        }
        
        return super.mainButtonTitle
    }
    
    override var isOnboardingFinished: Bool {
        if case .intro = currentStep, steps.count == 1 {
            return true
        }
        
        return super.isOnboardingFinished
    }
    
    override var isSupplementButtonVisible: Bool {
        switch currentStep {
        case .topup:
            return currentStep.isSupplementButtonVisible && canBuy
        default:
            return currentStep.isSupplementButtonVisible
        }
    }
    
    override var mainButtonSettings: TangemButtonSettings {
        var settings = super.mainButtonSettings
        
        switch currentStep {
        case .alert:
            settings.isEnabled = alertAccepted
        default: break
        }
        
        return settings
    }
    
    private var stackCalculator: StackCalculator = .init()
    private var twinInfo: TwinCardInfo
    private var stepUpdatesSubscription: AnyCancellable?
    
    private var canBuy: Bool { exchangeService.canBuy("BTC", blockchain: .bitcoin(testnet: false)) }
                                                      
    init(imageLoaderService: CardImageLoaderService, twinsService: TwinsWalletCreationService, exchangeService: ExchangeService, input: OnboardingInput) {
        self.imageLoaderService = imageLoaderService
        self.twinsService = twinsService
        
        if let twinInfo = input.cardInput.cardModel?.cardInfo.twinCardInfo {
//            pairNumber = AppTwinCardIdFormatter.format(cid: twinInfo.pairCid, cardNumber: nil)
            pairNumber = "\(twinInfo.series.pair.number)"
//            if twinInfo.series.number != 1 {
//                self.twinInfo = .init(cid: "",
//                                      series: twinInfo.series.pair,
//                                      pairPublicKey: nil)
//            } else {
                self.twinInfo = twinInfo
//            }
        } else {
            fatalError("Wrong card model passed to Twins onboarding view model")
        }
        
        super.init(exchangeService: exchangeService, input: input)
        if case let .twins(steps) = input.steps {
            self.steps = steps
            
            if case .topup = steps.first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.updateCardBalance()
                }
            }
        }
        if isFromMain {
            displayTwinImages = true
        }
        
        if case .alert = steps.first {
            retwinMode = true //todo: fix it
        }
        
        twinsService.setupTwins(for: twinInfo)
        bind()
        loadSecondTwinImage()
        
       
    }
    
    override func setupContainer(with size: CGSize) {
        stackCalculator.setup(for: size, with: .init(topCardSize: TwinOnboardingCardLayout.first.frame(for: .first, containerSize: size),
                                                     topCardOffset: .init(width: 0, height: 0.06 * size.height),
                                                     cardsVerticalOffset: 20,
                                                     scaleStep: 0.14,
                                                     opacityStep: 0.65,
                                                     numberOfCards: 2,
                                                     maxCardsInStack: 2))
        super.setupContainer(with: size)
    }
    
    override func playInitialAnim(includeInInitialAnim: (() -> Void)? = nil) {
        super.playInitialAnim {
            self.displayTwinImages = true
        }
    }
    
    override func onOnboardingFinished(for cardId: String) {
        super.onOnboardingFinished(for: cardId)
    
        //remove pair cid
        if let pairCardId = twinsService.twinPairCardId {
            super.onOnboardingFinished(for: pairCardId)
        }
    }
    
    override func mainButtonAction() {
        switch currentStep {
        case .welcome:
            if assembly.isPreview {
                goToNextStep()
            }
        case .intro:
            fallthrough
        case .done, .success, .alert:
            goToNextStep()
        case .first:
            if !retwinMode, !(userPrefsService?.cardsStartedActivation.contains(twinInfo.cid) ?? false) {
                userPrefsService?.cardsStartedActivation.append(twinInfo.cid)
            }
            
            if twinsService.step.value != .first {
                twinsService.resetSteps()
                stepUpdatesSubscription = nil
            }
            fallthrough
        case .second:
            fallthrough
        case .third:
            isMainButtonBusy = true
            subscribeToStepUpdates()
            if assembly.isPreview {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.isMainButtonBusy = false
                    self.goToNextStep()
                }
                return
            }
            twinsService.executeCurrentStep()
        case .topup:
            if canBuy {
                navigation.onboardingToBuyCrypto = true
            } else {
                supplementButtonAction()
            }
        }
    }
    
    override func goToNextStep() {
        super.goToNextStep()
        if case .intro = currentStep, assembly.isPreview {
            withAnimation {
                isNavBarVisible = true
                displayTwinImages = true
            }
        }
        
        switch currentStep {
        case .done, .success:
            withAnimation {
                refreshButtonState = .doneCheckmark
                fireConfetti()
            }
        default:
            break
        }
    }
    
    override func reset(includeInResetAnim: (() -> Void)? = nil) {
        super.reset {
            self.displayTwinImages = false
        }
    }
    
    override func supplementButtonAction() {
        switch currentStep {
        case .topup:
            withAnimation {
                isAddressQrBottomSheetPresented = true
            }
        default:
            break
        }
    }
    
    override func setupCardsSettings(animated: Bool, isContainerSetup: Bool) {
        // this condition is needed to prevent animating stack when user is trying to dismiss modal sheet
        mainCardSettings = TwinOnboardingCardLayout.first.animSettings(at: currentStep, containerSize: containerSize, stackCalculator: stackCalculator, animated: animated && !isContainerSetup)
        supplementCardSettings = TwinOnboardingCardLayout.second.animSettings(at: currentStep, containerSize: containerSize, stackCalculator: stackCalculator, animated: animated && !isContainerSetup)
    }
    
    override func backButtonAction() {
        switch currentStep {
        case .second, .third:
            alert = AlertBinder(alert: AlertBuilder.makeOkGotItAlert(message: "onboarding_twin_exit_warning".localized))
        default:
            back()
        }
    }
    
    private func back() {
        if isFromMain {
            input.successCallback?()
        } else {
            reset()
        }
    }
    
    private func bind() {
        twinsService
            .isServiceBusy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isServiceBudy in
                self?.isMainButtonBusy = isServiceBudy
            }
            .store(in: &bag)
    }
    
    private func subscribeToStepUpdates() {
        stepUpdatesSubscription = twinsService.step
            .receive(on: DispatchQueue.main)
            .combineLatest(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
            .sink(receiveValue: { [unowned self] (newStep, _) in
                switch (self.currentStep, newStep) {
                case (.first, .second), (.second, .third), (.third, .done):
                    if newStep == .done {
                        if input.isStandalone {
                            self.fireConfetti()
                        } else {
                            self.updateCardBalance()
                        }
                    }
                    
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.5)) {
                            self.currentStepIndex += 1
                            self.currentCardIndex = self.currentStep.topTwinCardIndex
                            self.setupCardsSettings(animated: true, isContainerSetup: false)
                        }
                    }
                default:
                    print("Wrong state while twinning cards: current - \(self.currentStep), new - \(newStep)")
                }
                
                if let pairCardId = twinsService.twinPairCardId,
                   let userService = userPrefsService,
                   !retwinMode,
                   !userService.cardsStartedActivation.contains(pairCardId) {
                    userPrefsService?.cardsStartedActivation.append(pairCardId)
                }
            })
    }
    
    private func loadSecondTwinImage() {
        imageLoaderService.loadTwinImage(for: twinInfo.series.pair.number)
            .zip($cardImage.compactMap { $0 })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (paired, main) in
                guard let self = self else { return }
                
                self.firstTwinImage = main
                self.secondTwinImage = paired
                //            withAnimation {
                //                self.displayTwinImages = true
                //            }
            }
            .store(in: &bag)
    }
}
