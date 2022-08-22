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
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    @Injected(\.tokenItemsRepository) private var tokensRepo: TokenItemsRepository
    @Injected(\.onboardingStepsSetupService) private var stepsSetupService: OnboardingStepsSetupService

    @Published var isCardScanned: Bool = true

    override var currentStep: SingleCardOnboardingStep {
        guard currentStepIndex < steps.count else {
            return .welcome
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
           exchangeService.canBuy(blockchain.currencySymbol, amountType: .coin, blockchain: blockchain) {
            return true
        }

        return false
    }

    required init(input: OnboardingInput, coordinator: OnboardingTopupRoutable) {
        super.init(input: input, coordinator: coordinator)

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

    override func mainButtonAction() {
        switch currentStep {
        case .welcome:
            fallthrough
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
                    openCryptoShop()
                }
            } else {
                supplementButtonAction()
            }
        case .successTopup:
            fallthrough
        case .success:
            goToNextStep()
        }
    }

    override func supplementButtonAction() {
        switch currentStep {
        case .topup:
            openQR()
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
                if let defaultEntry = cardInfo.defaultStorageEntry {
                    self?.tokensRepo.append([defaultEntry], for: cardInfo.card.cardId)
                } else {
                    let blockchains = SupportedTokenItems().predefinedBlockchains(isDemo: false, testnet: cardInfo.isTestnet)
                    self?.tokensRepo.append(blockchains, for: cardInfo.card.cardId, style: cardInfo.card.derivationStyle)
                }
            }

            if cardInfo.isTangemNote {
                AppSettings.shared.cardsStartedActivation.append(cardInfo.card.cardId)
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
            let previewModel = PreviewCard.ethEmptyNote.cardModel
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
