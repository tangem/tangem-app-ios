//
//  TwinsOnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class TwinsOnboardingViewModel: OnboardingTopupViewModel<TwinsOnboardingStep> {
    
    weak var userPrefsService: UserPrefsService!
    
    unowned var twinsService: TwinsWalletCreationService
    unowned var imageLoaderService: CardImageLoaderService
    
    @Published var firstTwinImage: UIImage?
    @Published var secondTwinImage: UIImage?
    @Published var pairNumber: String
    @Published var currentCardIndex: Int = 0
    
    override var currentStep: TwinsOnboardingStep {
        guard currentStepIndex < steps.count else {
            return .intro(pairNumber: pairNumber)
        }

        return steps[currentStepIndex]
    }
    
    override var title: LocalizedStringKey {
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
        
        if case .topup = currentStep, !exchangeService.canBuyCrypto {
            return currentStep.supplementButtonTitle
        }
        
        return super.mainButtonTitle
    }
    
    override var isSupplementButtonVisible: Bool {
        switch currentStep {
        case .topup:
            return currentStep.isSupplementButtonVisible && exchangeService.canBuyCrypto
        default:
            return currentStep.isSupplementButtonVisible
        }
    }
    
    private var bag: Set<AnyCancellable> = []
    private var stackCalculator: StackCalculator = .init()
    private var twinInfo: TwinCardInfo
    private var stepUpdatesSubscription: AnyCancellable?
    
    init(imageLoaderService: CardImageLoaderService, twinsService: TwinsWalletCreationService, exchangeService: ExchangeService, input: OnboardingInput) {
        self.imageLoaderService = imageLoaderService
        self.twinsService = twinsService
        if let twinInfo = input.cardModel.cardInfo.twinCardInfo {
//            pairNumber = TapTwinCardIdFormatter.format(cid: twinInfo.pairCid, cardNumber: nil)
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
        }
        
        twinsService.setupTwins(for: twinInfo)
        bind()
        loadImages()
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
    
    override func executeStep() {
        switch currentStep {
        case .intro:
            userPrefsService.cardsStartedActivation.append(twinInfo.cid)
//            userPrefsService.cardsStartedActivation.append(twinInfo.pairCid)
            fallthrough
        case .confetti, .done:
            goToNextStep()
        case .first:
            if twinsService.step.value != .first {
                twinsService.resetSteps()
                stepUpdatesSubscription = nil
            }
            fallthrough
        case .second, .third:
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
            if exchangeService.canBuyCrypto {
                navigation.onboardingToBuyCrypto = true
            } else {
                supplementButtonAction()
            }
        }
    }
    
    override func goToNextStep() {
       super.goToNextStep()
        if case .confetti = currentStep {
            withAnimation {
                refreshButtonState = .doneCheckmark
                shouldFireConfetti = true
            }
        }
    }
    
    func reset() {
        guard !assembly.isPreview else {
            withAnimation {
                currentStepIndex = 0
                setupCardsSettings(animated: true)
            }
            
            return
        }
        
        // Remove reset logic
        withAnimation {
            navigation.onboardingReset = true
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
    
    override func setupCardsSettings(animated: Bool) {
        mainCardSettings = TwinOnboardingCardLayout.first.animSettings(at: currentStep, containerSize: containerSize, stackCalculator: stackCalculator, animated: animated)
        supplementCardSettings = TwinOnboardingCardLayout.second.animSettings(at: currentStep, containerSize: containerSize, stackCalculator: stackCalculator, animated: animated)
    }
    
    private func bind() {
        twinsService
            .isServiceBusy
            .receive(on: DispatchQueue.main)
            .sink { isServiceBudy in
                self.isMainButtonBusy = isServiceBudy
            }
            .store(in: &bag)
    }
    
    private func subscribeToStepUpdates() {
        guard stepUpdatesSubscription == nil else {
            return
        }
        
        stepUpdatesSubscription = twinsService.step
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] newStep in
                switch (self.currentStep, newStep) {
                case (.first, .second), (.second, .third), (.third, .done):
                    if newStep == .done {
                        self.updateCardBalance()
                    }
                    withAnimation {
                        self.currentStepIndex += 1
                        self.currentCardIndex = self.currentStep.topTwinCardIndex
                        setupCardsSettings(animated: true)
                    }
                default:
                    print("Wrong state while twinning cards")
                }
            })
    }
    
    private func loadImages() {
        Publishers.Zip (
            imageLoaderService.backedLoadImage(.twinCardOne),
            imageLoaderService.backedLoadImage(.twinCardTwo)
        )
        .receive(on: DispatchQueue.main)
        .sink { completion in
            if case let .failure(error) = completion {
                print("Failed to load twin cards images. Reason: \(error)")
            }
        } receiveValue: { [weak self] (first, second) in
            guard let self = self else { return }
            
            withAnimation {
                self.firstTwinImage = self.twinInfo.series.number == 1 ? first : second
                self.secondTwinImage = self.twinInfo.series.number == 1 ? second : first
            }
        }
        .store(in: &bag)
    }
    
}
