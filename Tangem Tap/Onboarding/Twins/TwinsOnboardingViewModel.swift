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



class TwinsOnboardingViewModel: ViewModel {
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var userPrefsService: UserPrefsService!
    
    unowned var exchangeService: ExchangeService
    unowned var twinsService: TwinsWalletCreationService
    unowned var imageLoaderService: CardImageLoaderService
    
    @Published var firstTwinImage: UIImage?
    @Published var secondTwinImage: UIImage?
    @Published var pairNumber: String
    @Published var firstTwinSettings: AnimatedViewSettings = .zero
    @Published var secondTwinSettings: AnimatedViewSettings = .zero
    
    @Published var steps: [TwinsOnboardingStep] =
//        []
        TwinsOnboardingStep.previewCases
    
    @Published var currentStepIndex: Int = 0 {
        didSet {
            currentCardIndex = currentStep.topTwinCardIndex
        }
    }
    @Published var isModelBusy: Bool = false
    @Published var isAddressQrBottomSheetPresented: Bool = false
    @Published var refreshButtonState: OnboardingCircleButton.State = .refreshButton
    @Published var cardBalance: String = "0.00 BTC"
    @Published var shouldFireConfetti: Bool = false
    @Published var currentCardIndex: Int = 0
    
    var currentStep: TwinsOnboardingStep {
        guard currentStepIndex < steps.count else {
            return .intro(pairNumber: pairNumber)
        }
        
        return steps[currentStepIndex]
    }
    
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
    
    private var bag: Set<AnyCancellable> = []
    private var isFromMain = false
    private var containerSize: CGSize = .zero
    private var stackCalculator: StackCalculator = .init()
    
    private var successCallback: (() -> Void)?
    private var walletModelUpdateCancellable: AnyCancellable?
    
    private var cardModel: CardViewModel
    private var twinInfo: TwinCardInfo
    
    init(imageLoaderService: CardImageLoaderService, twinsService: TwinsWalletCreationService, exchangeService: ExchangeService, input: CardOnboardingInput) {
        self.imageLoaderService = imageLoaderService
        self.twinsService = twinsService
        self.exchangeService = exchangeService
        successCallback = input.successCallback
        cardModel = input.cardModel
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
        if case let .twins(steps) = input.steps {
            self.steps = steps
        }
        isFromMain = true
        
        twinsService.setupTwins(for: twinInfo)
        bind()
        loadImages()
    }
    
    func setupContainerSize(_ size: CGSize) {
        let isInitialSetup = containerSize == .zero
        containerSize = size
        stackCalculator.setup(for: size, with: .init(topCardSize: TwinOnboardingCardLayout.first.frame(for: .first, containerSize: size),
                                                     cardsVerticalOffset: 20,
                                                     scaleStep: 0.14,
                                                     opacityStep: 0.65,
                                                     numberOfCards: 2,
                                                     maxCardsInStack: 2))
        setupCardsSettings(animated: !isInitialSetup)
    }
    
    func executeStep() {
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
            isModelBusy = true
            subscribeToStepUpdates()
            if assembly.isPreview {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.isModelBusy = false
                    self.goToNextStep()
                }
                return
            }
            twinsService.executeCurrentStep()
        case .topup:
            navigation.onboardingToBuyCrypto = true
        }
    }
    
    func goToNextStep() {
        var newIndex = currentStepIndex + 1
        if newIndex >= steps.count {
            newIndex = assembly.isPreview ? 0 : steps.count - 1
        }
        
        if case .done = steps[newIndex], !assembly.isPreview {
            DispatchQueue.main.async {
                self.successCallback?()
            }
            return
        }
        
        withAnimation {
            currentStepIndex = newIndex
            
            setupCardsSettings(animated: true)
            if case .confetti = steps[newIndex] {
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
    
    func updateCardBalance() {
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
    
    private func bind() {
        twinsService
            .isServiceBusy
            .receive(on: DispatchQueue.main)
            .sink { isServiceBudy in
                self.isModelBusy = isServiceBudy
            }
            .store(in: &bag)
    }
    
    
    private var stepUpdatesSubscription: AnyCancellable?
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
            
            self.firstTwinImage = first
            self.secondTwinImage = second
        }
        .store(in: &bag)
    }
    
    private func updateCardBalanceText(for model: WalletModel) {
        withAnimation {
            cardBalance = model.getBalance(for: .coin)
        }
    }
    
    private func setupCardsSettings(animated: Bool) {
        firstTwinSettings = TwinOnboardingCardLayout.first.animSettings(at: currentStep, containerSize: containerSize, stackCalculator: stackCalculator, animated: animated)
        secondTwinSettings = TwinOnboardingCardLayout.second.animSettings(at: currentStep, containerSize: containerSize, stackCalculator: stackCalculator, animated: animated)
    }
    
}
