//
//  TwinsOnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk
import TangemSdk

class OnboardingViewModel<Step: OnboardingStep>: ViewModel {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    
    let navbarSize: CGSize = .init(width: UIScreen.main.bounds.width, height: 44)
    
    @Published var steps: [Step] = []
    @Published var currentStepIndex: Int = 0
    @Published var isMainButtonBusy: Bool = false
    @Published var shouldFireConfetti: Bool = false
    @Published var isInitialAnimPlayed = false
    
    var currentStep: Step { steps[currentStepIndex] }
    
    var currentProgress: CGFloat {
        CGFloat(currentStep.progressStep) / CGFloat(Step.maxNumberOfSteps)
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
        
        return currentStep.mainButtonTitle
    }
    
    var supplementButtonTitle: LocalizedStringKey {
        if !isInitialAnimPlayed, let welcomteStep = input.welcomeStep {
            return welcomteStep.supplementButtonTitle
        }
        
        return currentStep.supplementButtonTitle
    }
    
    var isSupplementButtonVisible: Bool { currentStep.isSupplementButtonVisible }
    
    let successCallback: (() -> Void)?
    let input: CardOnboardingInput
    
    init(input: CardOnboardingInput) {
        self.input = input
        successCallback = input.successCallback
    }
    
    func playInitialAnim() {
        withAnimation {
            isInitialAnimPlayed = true
            setupCardsSettings(animated: true)
        }
    }
    
    func goToNextStep() {
        var newIndex = currentStepIndex + 1
        if newIndex >= steps.count {
            newIndex = assembly.isPreview ? 0 : steps.count - 1
        }
        
        if steps[newIndex].isOnboardingFinished, !assembly.isPreview {
            DispatchQueue.main.async {
                self.successCallback?()
            }
            return
        }
        
        withAnimation {
            currentStepIndex = newIndex
            
            setupCardsSettings(animated: true)
        }
    }
    
    func executeStep() {
        fatalError("Not implemented")
    }
    
    func setupCardsSettings(animated: Bool) {
        fatalError("Not implemented")
    }
    
}

class OnboardingTopupViewModel<Step: OnboardingStep>: OnboardingViewModel<Step> {
    unowned var exchangeService: ExchangeService
    
    @Published var isAddressQrBottomSheetPresented: Bool = false
    @Published var refreshButtonState: OnboardingCircleButton.State = .refreshButton
    @Published var cardBalance: String = "0.00"
    @Published var currentCardIndex: Int = 0
    
    var previewUpdates: Int = 0
    var walletModelUpdateCancellable: AnyCancellable?
    
    var cardModel: CardViewModel
    
    var canBuyCrypto: Bool { exchangeService.canBuyCrypto }
    
    var buyCryptoURL: URL? {
        if let wallet = cardModel.wallets?.first {
            return exchangeService.getBuyUrl(currencySymbol: wallet.blockchain.currencySymbol,
                                             walletAddress: wallet.address)
        }
        return nil
    }
    
    var buyCryptoCloseUrl: String { exchangeService.successCloseUrl.removeLatestSlash() }
    
    var shareAddress: String {
        cardModel.walletModels?.first?.shareAddressString(for: 0) ?? ""
    }
    
    var walletAddress: String {
        cardModel.walletModels?.first?.displayAddress(for: 0) ?? ""
    }
    
    init(exchangeService: ExchangeService, input: CardOnboardingInput) {
        self.exchangeService = exchangeService
        self.cardModel = input.cardModel
        super.init(input: input)
    }
    
    func updateCardBalance() {
        if assembly.isPreview {
            previewUpdates += 1
            
            if self.previewUpdates >= 3 {
                self.cardModel = Assembly.PreviewCard.scanResult(for: .cardanoNote, assembly: assembly).cardModel!
                self.previewUpdates = 0
            }
        }
        
        guard
            let walletModel = cardModel.walletModels?.first,
            walletModelUpdateCancellable == nil
        else { return }
        
        
        refreshButtonState = .activityIndicator
        walletModelUpdateCancellable = walletModel.$state
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] walletModelState in
                guard let self = self else { return }
                
                self.updateCardBalanceText(for: walletModel)
                switch walletModelState {
                case .noAccount(let message):
                    print(message)
                    fallthrough
                case .idle:
                    if !walletModel.isEmptyIncludingPendingIncomingTxs {
                        self.goToNextStep()
                        return
                    }
                    withAnimation {
                        self.refreshButtonState = .refreshButton
                    }
                case .failed(let error):
                    print(error)
                    withAnimation {
                        self.refreshButtonState = .refreshButton
                    }
                case .loading, .created:
                    return
                }
                self.walletModelUpdateCancellable = nil
            }
        walletModel.update(silent: false)
    }
    
    func updateCardBalanceText(for model: WalletModel) {
        withAnimation {
            cardBalance = model.getBalance(for: .coin)
        }
    }
    
}

class TwinsTwinsTwins: OnboardingTopupViewModel<TwinsOnboardingStep> {
    
}

class TwinsOnboardingViewModel: OnboardingTopupViewModel<TwinsOnboardingStep> {
    
//    weak var assembly: Assembly!
//    weak var navigation: NavigationCoordinator!
    weak var userPrefsService: UserPrefsService!
    
//    unowned var exchangeService: ExchangeService
    unowned var twinsService: TwinsWalletCreationService
    unowned var imageLoaderService: CardImageLoaderService
    
    @Published var firstTwinImage: UIImage?
    @Published var secondTwinImage: UIImage?
    @Published var pairNumber: String
    @Published var firstTwinSettings: AnimatedViewSettings = .zero
    @Published var secondTwinSettings: AnimatedViewSettings = .zero
    
//    [REDACTED_USERNAME] var steps: [TwinsOnboardingStep] =
//        []
//        TwinsOnboardingStep.previewCases
    
//    [REDACTED_USERNAME] var currentStepIndex: Int = 0 {
//        didSet {
//            currentCardIndex = currentStep.topTwinCardIndex
//        }
//    }
//    [REDACTED_USERNAME] var isModelBusy: Bool = false
//    [REDACTED_USERNAME] var isAddressQrBottomSheetPresented: Bool = false
//    [REDACTED_USERNAME] var refreshButtonState: OnboardingCircleButton.State = .refreshButton
//    [REDACTED_USERNAME] var cardBalance: String = "0.00 BTC"
//    [REDACTED_USERNAME] var shouldFireConfetti: Bool = false
//    [REDACTED_USERNAME] var currentCardIndex: Int = 0
//    [REDACTED_USERNAME] private(set) var isInitialAnimPlayed = false
    
//    let navbarSize: CGSize = .init(width: UIScreen.main.bounds.width, height: 44)
    
//    var currentProgress: CGFloat {
//        CGFloat(currentStep.progressStep) / CGFloat(TwinsOnboardingStep.maxNumberOfSteps)
//    }
    
//    var currentStep: TwinsOnboardingStep {
//        guard currentStepIndex < steps.count else {
//            return .intro(pairNumber: pairNumber)
//        }
//
//        return steps[currentStepIndex]
//    }
    
//    var title: LocalizedStringKey {
//        if !isInitialAnimPlayed, let welcomeStep = input.welcomeStep {
//            return welcomeStep.title
//        }
//
//        return currentStep.title
//    }
//
//    var subtitle: LocalizedStringKey {
//        if !isInitialAnimPlayed, let welcomteStep = input.welcomeStep {
//            return welcomteStep.subtitle
//        }
//
//        return currentStep.subtitle
//    }
    
    override var mainButtonTitle: LocalizedStringKey {
        if !isInitialAnimPlayed {
            return super.mainButtonTitle
        }
        
        if case .topup = currentStep, !exchangeService.canBuyCrypto {
            return currentStep.supplementButtonTitle
        }
        
        return super.mainButtonTitle
    }
    
//    var supplementButtonTitle: LocalizedStringKey {
//        if !isInitialAnimPlayed, let welcomteStep = input.welcomeStep {
//            return welcomteStep.supplementButtonTitle
//        }
//
//        return currentStep.supplementButtonTitle
//    }
    
    override var isSupplementButtonVisible: Bool {
        switch currentStep {
        case .topup:
            return currentStep.isSupplementButtonVisible && exchangeService.canBuyCrypto
        default:
            return currentStep.isSupplementButtonVisible
        }
    }
    
//    var buyCryptoURL: URL? {
//        if let wallet = cardModel.wallets?.first {
//            return exchangeService.getBuyUrl(currencySymbol: wallet.blockchain.currencySymbol,
//                                             walletAddress: wallet.address)
//        }
//        return nil
//    }
//
//    var buyCryptoCloseUrl: String { exchangeService.successCloseUrl.removeLatestSlash() }
//
//    var shareAddress: String {
//        cardModel.walletModels?.first?.shareAddressString(for: 0) ?? ""
//    }
//
//    var walletAddress: String {
//        cardModel.walletModels?.first?.displayAddress(for: 0) ?? ""
//    }
    
    private(set) var isFromMain = false
    
//    private let input: CardOnboardingInput
    
    private var bag: Set<AnyCancellable> = []
    
    private var containerSize: CGSize = .zero
    private var stackCalculator: StackCalculator = .init()
    
//    private var successCallback: (() -> Void)?
//    private var walletModelUpdateCancellable: AnyCancellable?
    
//    private var cardModel: CardViewModel
    private var twinInfo: TwinCardInfo
    private var stepUpdatesSubscription: AnyCancellable?
//    private var previewUpdates: Int = 0
    
    init(imageLoaderService: CardImageLoaderService, twinsService: TwinsWalletCreationService, exchangeService: ExchangeService, input: CardOnboardingInput) {
        self.imageLoaderService = imageLoaderService
        self.twinsService = twinsService
//        self.exchangeService = exchangeService
//        self.input = input
//        successCallback = input.successCallback
//        cardModel = input.cardModel
        if let twinInfo = input.cardModel.cardInfo.twinCardInfo {
            pairNumber = TapTwinCardIdFormatter.format(cid: twinInfo.pairCid, cardNumber: nil)
            if twinInfo.series.number != 1 {
                self.twinInfo = .init(cid: twinInfo.pairCid,
                                      series: twinInfo.series.pair,
                                      pairCid: twinInfo.cid,
                                      pairPublicKey: nil)
            } else {
                self.twinInfo = twinInfo
            }
        } else {
            fatalError("Wrong card model passed to Twins onboarding view model")
        }
        
        super.init(exchangeService: exchangeService, input: input)
        if case let .twins(steps) = input.steps {
            self.steps = steps
        }
        
        if let cardsSettings = input.cardsPosition {
            firstTwinSettings = cardsSettings.dark
            secondTwinSettings = cardsSettings.light
            isInitialAnimPlayed = false
        } else {
            isFromMain = true
            isInitialAnimPlayed = true
        }
        
        twinsService.setupTwins(for: twinInfo)
        bind()
        loadImages()
    }
    
    func setupContainerSize(_ size: CGSize) {
        let isInitialSetup = containerSize == .zero
        containerSize = size
        stackCalculator.setup(for: size, with: .init(topCardSize: TwinOnboardingCardLayout.first.frame(for: .first, containerSize: size),
                                                     topCardOffset: .init(width: 0, height: 0.06 * size.height),
                                                     cardsVerticalOffset: 20,
                                                     scaleStep: 0.14,
                                                     opacityStep: 0.65,
                                                     numberOfCards: 2,
                                                     maxCardsInStack: 2))
        if firstTwinSettings == .zero, secondTwinSettings == .zero {
            setupCardsSettings(animated: !isInitialSetup)
        }
    }
    
//    func playInitialAnim() {
//        withAnimation {
//            isInitialAnimPlayed = true
//            setupCardsSettings(animated: true)
//        }
//    }
    
    override func executeStep() {
        switch currentStep {
        case .intro:
            userPrefsService.cardsStartedActivation.append(twinInfo.cid)
            userPrefsService.cardsStartedActivation.append(twinInfo.pairCid)
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
//        var newIndex = currentStepIndex + 1
//        if newIndex >= steps.count {
//            newIndex = assembly.isPreview ? 0 : steps.count - 1
//        }
//
//        if case .done = steps[newIndex], !assembly.isPreview {
//            DispatchQueue.main.async {
//                self.successCallback?()
//            }
//            return
//        }
//
//        withAnimation {
//            currentStepIndex = newIndex
//
//            setupCardsSettings(animated: true)
        super.goToNextStep()
        withAnimation {
            if case .confetti = currentStep {
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
        
        withAnimation {
            navigation.onboardingReset = true
        }
    }
    
    func supplementButtonAction() {
        switch currentStep {
        case .topup:
            withAnimation {
                isAddressQrBottomSheetPresented = true
            }
        default:
            break
        }
    }
    
//    func updateCardBalance() {
//        if assembly.isPreview {
//            previewUpdates += 1
//
//            if self.previewUpdates >= 3 {
//                self.cardModel = Assembly.PreviewCard.scanResult(for: .cardanoNote, assembly: assembly).cardModel!
//                self.previewUpdates = 0
//            }
//        }
//
//        guard
//            let walletModel = cardModel.walletModels?.first,
//            walletModelUpdateCancellable == nil
//        else { return }
//
//
//        refreshButtonState = .activityIndicator
//        walletModelUpdateCancellable = walletModel.$state
//            .receive(on: DispatchQueue.main)
//            .dropFirst()
//            .sink { [weak self] walletModelState in
//                guard let self = self else { return }
//
//                self.updateCardBalanceText(for: walletModel)
//                switch walletModelState {
//                case .noAccount(let message):
//                    print(message)
//                    fallthrough
//                case .idle:
//                    if !walletModel.isEmptyIncludingPendingIncomingTxs {
//                        self.goToNextStep()
//                        return
//                    }
//                    withAnimation {
//                        self.refreshButtonState = .refreshButton
//                    }
//                case .failed(let error):
//                    print(error)
//                    withAnimation {
//                        self.refreshButtonState = .refreshButton
//                    }
//                case .loading, .created:
//                    return
//                }
//                self.walletModelUpdateCancellable = nil
//            }
//        walletModel.update(silent: false)
//    }
    
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
                    withAnimation {
                        self.currentStepIndex += 1
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
                self.firstTwinImage = first
                self.secondTwinImage = second
            }
        }
        .store(in: &bag)
    }
    
//    private func updateCardBalanceText(for model: WalletModel) {
//        withAnimation {
//            cardBalance = model.getBalance(for: .coin)
//        }
//    }
    
    override func setupCardsSettings(animated: Bool) {
        firstTwinSettings = TwinOnboardingCardLayout.first.animSettings(at: currentStep, containerSize: containerSize, stackCalculator: stackCalculator, animated: animated)
        secondTwinSettings = TwinOnboardingCardLayout.second.animSettings(at: currentStep, containerSize: containerSize, stackCalculator: stackCalculator, animated: animated)
    }
    
}
