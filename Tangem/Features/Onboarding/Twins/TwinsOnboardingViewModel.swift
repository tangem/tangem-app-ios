//
//  TwinsOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import Combine
import TangemUI

class TwinsOnboardingViewModel: OnboardingViewModel<TwinsOnboardingStep, OnboardingCoordinator>, ObservableObject {
    @Published var firstTwinImage: Image?
    @Published var secondTwinImage: Image?
    @Published var currentCardIndex: Int = 0
    @Published var displayTwinImages: Bool = false
    @Published var alertAccepted: Bool = false

    var retwinMode: Bool = false

    override var navbarTitle: String {
        currentStep.navbarTitle
    }

    override var title: String? {
        if !isInitialAnimPlayed {
            return super.title
        }

        if twinCardSeries.number != 1 {
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

    override var isSupportButtonVisible: Bool {
        switch currentStep {
        case .success, .done: return false
        default: return super.isSupportButtonVisible
        }
    }

    // MARK: - Main Button settings

    override var mainButtonSettings: MainButton.Settings? {
        switch currentStep {
        case .saveUserWallet:
            return super.mainButtonSettings
        default:
            return nil
        }
    }

    // MARK: - Supplement button settings

    override var supplementButtonTitle: String {
        if !isInitialAnimPlayed {
            return super.supplementButtonTitle
        }

        if twinCardSeries.number != 1 {
            switch currentStep {
            case .first, .third:
                return TwinsOnboardingStep.second.supplementButtonTitle
            case .second:
                return TwinsOnboardingStep.first.supplementButtonTitle
            default:
                break
            }
        }

        return super.supplementButtonTitle
    }

    override var supplementButtonSettings: MainButton.Settings? {
        var settings = super.supplementButtonSettings

        switch currentStep {
        case .alert:
            settings?.isDisabled = !alertAccepted
        default:
            break
        }

        return settings
    }

    override var supplementButtonStyle: MainButton.Style {
        switch currentStep {
        case .intro, .success, .first, .second, .third, .done, .alert:
            return .primary
        default:
            return super.supplementButtonStyle
        }
    }

    override var supplementButtonIcon: MainButton.Icon? {
        if let icon = currentStep.supplementButtonIcon {
            return .trailing(icon)
        }

        return nil
    }

    var isCustomContentVisible: Bool {
        switch currentStep {
        case .saveUserWallet, .pushNotifications:
            return true
        default:
            return false
        }
    }

    var infoText: String? {
        currentStep.infoText
    }

    private var stackCalculator: StackCalculator = .init()
    private var twinCardSeries: TwinCardSeries
    private var stepUpdatesSubscription: AnyCancellable?
    private let twinsService: TwinsWalletCreationUtil
    private let imageProvider = TwinImageProvider()

    override init(input: OnboardingInput, coordinator: OnboardingCoordinator) {
        let twinData = input.twinData!

        twinCardSeries = twinData.series
        twinsService = .init(cardId: input.primaryCardId, twinData: twinData)

        super.init(input: input, coordinator: coordinator)

        if case .twins(let steps) = input.steps {
            self.steps = steps
        }

        if isFromMain {
            displayTwinImages = true
        }

        if case .alert = steps.first {
            retwinMode = true // [REDACTED_TODO_COMMENT]
        }

        bind()
        loadSecondTwinImage()
    }

    func onAppear() {
        if isInitialAnimPlayed {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playInitialAnim()
        }
    }

    override func setupContainer(with size: CGSize) {
        stackCalculator.setup(for: size, with: .init(
            topCardSize: TwinOnboardingCardLayout.first.frame(for: .first, containerSize: size),
            topCardOffset: .init(width: 0, height: 0.06 * size.height),
            cardsVerticalOffset: 20,
            scaleStep: 0.14,
            opacityStep: 0.65,
            numberOfCards: 2,
            maxCardsInStack: 2
        ))
        super.setupContainer(with: size)
    }

    override func playInitialAnim(includeInInitialAnim: (() -> Void)? = nil) {
        logAnalytics(.twinningScreenOpened)
        super.playInitialAnim {
            self.displayTwinImages = true
        }
    }

    override func onOnboardingFinished(for cardId: String) {
        super.onOnboardingFinished(for: cardId)

        // remove pair cid
        if let pairCardId = twinsService.twinPairCardId {
            AppSettings.shared.cardsStartedActivation.remove(pairCardId)
        }
    }

    // MARK: - Main button action

    override func mainButtonAction() {}

    // MARK: - Supplement button action

    override func supplementButtonAction() {
        switch currentStep {
        case .intro, .success, .done, .alert:
            goToNextStep()
        case .first:
            if !retwinMode {
                AppSettings.shared.cardsStartedActivation.insert(twinsService.firstTwinCid)
            }

            logAnalytics(.twinSetupStarted)

            // [REDACTED_TODO_COMMENT]
            if case .first = twinsService.step.value {} else {
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
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.onboardingTwinExitWarning)
        default:
            alert = AlertBuilder.makeExitAlert { [weak self] in
                guard let self else { return }

                // This part is related only to the twin cards, because for other card types
                // reset to factory settings goes not through onboarding screens. If back button
                // appearance logic will change in future - recheck also this code and update it accordingly
                if isOnboardingFinished {
                    onboardingDidFinish()
                } else {
                    closeOnboarding()
                }
            }
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

        twinsService
            .occuredError
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, error in
                if error.isCancellationError {
                    return
                }

                Analytics.logScanError(error, source: .onboarding, contextParams: viewModel.getContextParams())
                viewModel.alert = error.alertBinder
            }
            .store(in: &bag)

        $currentStepIndex
            .removeDuplicates()
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .receiveValue { [weak self] index in
                guard let steps = self?.steps,
                      index < steps.count else { return }

                let currentStep = steps[index]

                switch currentStep {
                case .done, .success:
                    withAnimation {
                        self?.fireConfetti()
                    }
                default:
                    break
                }
            }
            .store(in: &bag)
    }

    private func subscribeToStepUpdates() {
        stepUpdatesSubscription = twinsService.step
            .receive(on: DispatchQueue.main)
            .combineLatest(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
            .withWeakCaptureOf(self)
            .sink { values in
                let (viewModel, (newStep, _)) = values
                switch (viewModel.currentStep, newStep) {
                case (.first, .second):
                    if let originalUserWalletId = viewModel.input.userWalletToDelete {
                        viewModel.userWalletRepository.delete(
                            userWalletId: originalUserWalletId
                        )
                    }
                    fallthrough
                case (.second, .third), (.third, .done):
                    if case .done(let cardInfo) = newStep {
                        if !viewModel.retwinMode {
                            // userwallet remains deleted after retwin
                            viewModel.initializeUserWallet(from: cardInfo, walletCreationType: .privateKey)
                        }
                        if viewModel.input.isStandalone {
                            viewModel.fireConfetti()
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
                    AppLogger.info(
                        "Wrong state while twinning cards: current - \(viewModel.currentStep), new - \(newStep)"
                    )
                }

                if !viewModel.retwinMode {
                    if let pairCardId = viewModel.twinsService.twinPairCardId {
                        AppSettings.shared.cardsStartedActivation.insert(pairCardId)
                    }
                }
            }
    }

    private func loadSecondTwinImage() {
        imageProvider
            .loadTwinImagePublisher(cardNumber: twinCardSeries.pair.number)
            .zip($mainImage.compactMap { $0 })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paired, main in
                guard let self = self else { return }

                firstTwinImage = main
                secondTwinImage = Image(uiImage: paired)
            }
            .store(in: &bag)
    }
}
