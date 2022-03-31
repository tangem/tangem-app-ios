//
//  OnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import Combine

class SingleCardOnboardingViewModel: OnboardingTopupViewModel<SingleCardOnboardingStep>, ObservableObject {
    
    weak var cardsRepository: CardsRepository!
    weak var tokensRepo: TokenItemsRepository!
    weak var stepsSetupService: OnboardingStepsSetupService!
    
    @Published var isCardScanned: Bool = true
    
    override var currentStep: SingleCardOnboardingStep {
        guard currentStepIndex < steps.count else {
            return assembly.isPreview ? .createWallet : .welcome
        }

        return steps[currentStepIndex]
    }
    
    override var subtitle: LocalizedStringKey {
        if currentStep == .topup, cardModel!.cardInfo.walletData?.blockchain.lowercased() == "xrp" {
             return "onboarding_topup_subtitle_xrp"
        } else {
            return super.subtitle
        }
    }
    
    override var mainButtonTitle: LocalizedStringKey {
        if case .topup = currentStep, !canBuyCrypto {
            return "onboarding_button_receive_crypto"
        }
        
        return super.mainButtonTitle
    }
    
    override var isSupplementButtonVisible: Bool {
        switch currentStep {
        case .topup:
            return currentStep.isSupplementButtonVisible && canBuyCrypto
        default:
            return currentStep.isSupplementButtonVisible
        }
    }
    
    private var previewUpdateCounter: Int = 0
    private var walletCreatedWhileOnboarding: Bool = false
    private var scheduledUpdate: DispatchWorkItem?
    
    private var canBuyCrypto: Bool {
        if let blockchain = cardModel?.wallets?.first?.blockchain,
           exchangeService.canBuy(blockchain.currencySymbol, blockchain: blockchain) {
            return true
        }
        
        return false
    }
    
    override init(exchangeService: ExchangeService, input: OnboardingInput) {
        super.init(exchangeService: exchangeService, input: input)
        
        if case let .singleWallet(steps) = input.steps {
            self.steps = steps
        } else {
            fatalError("Wrong onboarding steps passed to initializer")
        }
        
        if steps.first == .topup && currentStep == .topup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.updateCardBalance()
            }
        }
    }
        
    // MARK: Functions

    override func goToNextStep() {
        super.goToNextStep()
        stepUpdate()
    }
    
    override func reset(includeInResetAnim: (() -> Void)? = nil) {
        super.reset {
            self.isCardScanned = false
        }
    }
    
    override func mainButtonAction() {
        switch currentStep {
        case .welcome:
            if assembly.isPreview {
                goToNextStep()
                withAnimation {
                    isNavBarVisible = true
                    isCardScanned = true
                }
            }
        case .createWallet:
            сreateWallet()
        case .topup:
            if canBuyCrypto {
                if cardModel?.cardInfo.card.isDemoCard ?? false {
                    alert = AlertBuilder.makeDemoAlert(okAction: {
                        DispatchQueue.main.async {
                            self.updateCardBalance()
                        }
                    })
                } else {
                    navigation.onboardingToBuyCrypto = true
                }
            } else {
                supplementButtonAction()
            }
        case .successTopup:
            if assembly.isPreview {
                reset()
            }
            fallthrough
        case .success:
            goToNextStep()
        }
    }
    
    override func supplementButtonAction() {
        switch currentStep {
        case .topup:
            isAddressQrBottomSheetPresented = true
        default:
            break
        }
    }
    
    override func setupCardsSettings(animated: Bool, isContainerSetup: Bool) {
        mainCardSettings = .init(targetSettings: SingleCardOnboardingCardsLayout.main.cardAnimSettings(for: currentStep,
                                                                                                       containerSize: containerSize,
                                                                                                       animated: animated),
                                 intermediateSettings: nil)
        supplementCardSettings = .init(targetSettings: SingleCardOnboardingCardsLayout.supplementary.cardAnimSettings(for: currentStep, containerSize: containerSize, animated: animated), intermediateSettings: nil)
    }
    
    private func сreateWallet() {
        isMainButtonBusy = true
        
        if assembly.isPreview {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.cardModel = Assembly.PreviewCard.scanResult(for: .cardanoNoteEmptyWallet, assembly: self.assembly).cardModel!
                self.updateCardBalanceText(for: self.cardModel!.walletModels!.first!)
                self.isMainButtonBusy = false
                self.goToNextStep()
            }
            return
        }
        
        let cardInfo = cardModel!.cardInfo
        
        var subscription: AnyCancellable? = nil
        
        subscription = Deferred {
            Future { (promise: @escaping Future<Void, Error>.Promise) in
                self.cardModel!.createWallet { result in
                    switch result {
                    case .success:
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .combineLatest(NotificationCenter.didBecomeActivePublisher)
        .first()
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.isMainButtonBusy = false
                print("Failed to create wallet. \(error)")
            }
            subscription.map { _ = self?.bag.remove($0) }
        } receiveValue: { [weak self] (_, _) in
            
            if cardInfo.isMultiWallet {
                let blockchains = SupportedTokenItems().predefinedBlockchains(isDemo: false)
                self?.tokensRepo.append(blockchains, for: cardInfo.card.cardId, batchId: cardInfo.card.batchId)
            }
            
            if cardInfo.isTangemNote {
                self?.userPrefsService?.cardsStartedActivation.append(cardInfo.card.cardId)
            }
            
            self?.cardModel?.updateState()
            self?.walletCreatedWhileOnboarding = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.isMainButtonBusy = false
                self?.goToNextStep()
            }
        }
        
        subscription?.store(in: &bag)
    }
    
    private func stepUpdate() {
        switch currentStep {
        case .topup:
            if let walletModel = self.cardModel?.walletModels?.first {
                updateCardBalanceText(for: walletModel)
            }
            
            if walletCreatedWhileOnboarding {
                return
            }
            
            withAnimation {
                isBalanceRefresherVisible = true
            }
            
            updateCardBalance()
        case .successTopup:
            withAnimation {
                refreshButtonState = .doneCheckmark
            }
            fallthrough
        case .success:
           fireConfetti()
        default:
            break
        }
    }
    
    private func readPreviewCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let previewModel = Assembly.PreviewCard.scanResult(for: .ethEmptyNote, assembly: self.assembly).cardModel!
            self.cardModel = previewModel
            self.stepsSetupService.steps(for: previewModel.cardInfo)
                .sink { _ in }
                    receiveValue: { [weak self] steps in
                        if case let .singleWallet(singleSteps) = steps {
                            self?.steps = singleSteps
                        }
                        self?.goToNextStep()
                        self?.isMainButtonBusy = false
                }
                .store(in: &self.bag)

        }
    }
}
