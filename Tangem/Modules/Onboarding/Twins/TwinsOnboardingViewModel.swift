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
    @Injected(\.cardImageLoader) var imageLoader: CardImageLoaderProtocol

    @Published var firstTwinImage: UIImage?
    @Published var secondTwinImage: UIImage?
    @Published var pairNumber: String
    @Published var currentCardIndex: Int = 0
    @Published var displayTwinImages: Bool = false
    @Published var alertAccepted: Bool = false

    var retwinMode: Bool = false

    override var currentStep: TwinsOnboardingStep {
        guard currentStepIndex < steps.count else {
            return .welcome
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
    private let twinsService: TwinsWalletCreationUtil

    private var canBuy: Bool { exchangeService.canBuy("BTC", amountType: .coin, blockchain: .bitcoin(testnet: false)) }

    required init(input: OnboardingInput, coordinator: OnboardingTopupRoutable) {
        guard let cardModel = input.cardInput.cardModel,
              case let .twin(twinData) = cardModel.cardInfo.walletData else {
            fatalError("Wrong card model passed to Twins onboarding view model")
        }

        self.pairNumber = "\(twinData.series.pair.number)"
        self.twinInfo = twinData
        self.twinsService = .init(card: cardModel)

        super.init(input: input, coordinator: coordinator)
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
            retwinMode = true // [REDACTED_TODO_COMMENT]
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

        // remove pair cid
        if let pairCardId = twinsService.twinPairCardId {
            super.onOnboardingFinished(for: pairCardId)
        }
    }

    override func mainButtonAction() {
        switch currentStep {
        case .welcome:
            fallthrough
        case .intro:
            fallthrough
        case .done, .success, .alert:
            goToNextStep()
        case .first:
            if !retwinMode, !(AppSettings.shared.cardsStartedActivation.contains(twinInfo.cid)) {
                AppSettings.shared.cardsStartedActivation.append(twinInfo.cid)
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
            twinsService.executeCurrentStep()
        case .topup:
            if canBuy {
                openCryptoShop()
            } else {
                supplementButtonAction()
            }
        }
    }

    override func goToNextStep() {
        super.goToNextStep()

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

    override func supplementButtonAction() {
        switch currentStep {
        case .topup:
            withAnimation {
                openQR()
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
            alert = AlertBuilder.makeOkGotItAlert(message: "onboarding_twin_exit_warning".localized)
        default:
            back()
        }
    }

    private func back() {
        if isFromMain {
            closeOnboarding()
        } else {
            popToRoot()
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
                   !retwinMode,
                   !AppSettings.shared.cardsStartedActivation.contains(pairCardId) {
                    AppSettings.shared.cardsStartedActivation.append(pairCardId)
                }
            })
    }

    private func loadSecondTwinImage() {
        imageLoader.loadTwinImage(for: twinInfo.series.pair.number)
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
