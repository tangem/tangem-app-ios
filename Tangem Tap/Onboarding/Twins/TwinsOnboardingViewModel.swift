//
//  TwinsOnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class TwinsOnboardingViewModel: ViewModel {
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var exchangeService: ExchangeService!
    
    unowned var twinsService: TwinsWalletCreationService
    unowned var imageLoaderService: CardImageLoaderService
    
    @Published var firstTwinImage: UIImage?
    @Published var secondTwinImage: UIImage?
    @Published var pairNumber: String
    
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
    
    @Published var steps: [TwinsOnboardingStep] =
//        []
        TwinsOnboardingStep.previewCases
    
    @Published var currentStepIndex: Int = 0
    @Published var isModelBusy: Bool = false
    
    private var bag: Set<AnyCancellable> = []
    private var isFromMain = false
    private var successCallback: (() -> Void)?
    
    private var cardModel: CardViewModel
    private var twinInfo: TwinCardInfo
    
    init(imageLoaderService: CardImageLoaderService, twinsService: TwinsWalletCreationService, input: CardOnboardingInput) {
        self.imageLoaderService = imageLoaderService
        self.twinsService = twinsService
        successCallback = input.successCallback
        cardModel = input.cardModel
        if let twinInfo = input.cardModel.cardInfo.twinCardInfo {
            pairNumber = TapTwinCardIdFormatter.format(cid: twinInfo.pairCid ?? "", cardNumber: nil)
            self.twinInfo = twinInfo
        } else {
            fatalError("Wrong card model passed to Twins onboarding view model")
        }
        isFromMain = true
        
        twinsService.setupTwins(for: twinInfo)
        bind()
        loadImages()
    }
    
    func executeStep() {
        var newIndex = currentStepIndex + 1
        if newIndex >= steps.count {
            newIndex = 0
        }
        
        if case .done = steps[newIndex] {
            newIndex = 0
        }
        
        switch currentStep {
        case .intro, .confetti, .done:
            withAnimation {
                currentStepIndex = newIndex
            }
        case .first:
            if twinsService.step.value != .first {
                twinsService.resetSteps()
            }
            fallthrough
        case .second, .third:
            twinsService.executeCurrentStep()
        case .topup:
            navigation.onboardingToBuyCrypto = true
        }
    }
    
    func reset() {
        withAnimation {
            currentStepIndex = 0
        }
    }
    
    func supplementButtonAction() {
        
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
    
}
