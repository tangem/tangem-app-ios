//
//  WalletOnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk

class WalletOnboardingViewModel: OnboardingViewModel<WalletOnboardingStep> {
    
    let backupService: BackupService
    
    @Published var mainCardImage: UIImage
    @Published var thirdCardSettings: AnimatedViewSettings = .zero
    
    private var stackCalculator: StackCalculator = .init()
    private var fanStackCalculator: FanStackCalculator = .init()
    private var bag: Set<AnyCancellable> = []
    private var stepPublisher: AnyCancellable?
    
    override var isBackButtonVisible: Bool {
        true
    }
    
    override var title: LocalizedStringKey {
        switch currentStep {
        case .selectBackupCards:
            switch backupCardsAddedCount {
            case 0: return "onboarding_title_no_backup_cards"
            case 1: return "onboarding_title_one_backup_card"
            default: return "onboarding_title_two_backup_cards"
            }
        default: return super.title
        }
    }
    
    override var subtitle: LocalizedStringKey {
        switch currentStep {
        case .selectBackupCards:
            switch backupCardsAddedCount {
            case 0: return "onboarding_subtitle_no_backup_cards"
            case 1: return "onboarding_subtitle_one_backup_card"
            default: return "onboarding_subtitle_two_backup_cards"
            }
        default: return super.subtitle
        }
    }
    
    override var mainButtonSettings: TangemButtonSettings {
        .init(
            title: mainButtonTitle,
            size: .wide,
            action: mainButtonAction,
            isBusy: isMainButtonBusy,
            isEnabled: isMainButtonEnabled,
            isVisible: true,
            color: mainButtonColor,
            systemIconName: mainButtonIconName,
            iconPosition: .leading
        )
    }
    
    override var mainButtonTitle: LocalizedStringKey {
        switch currentStep {
        case .selectBackupCards:
            return canAddBackupCards ?
                "onboarding_button_add_backup_card" :
                "onboarding_button_max_backup_cards_added"
        default: return super.mainButtonTitle
        }
    }
    
    var mainButtonColor: ButtonColorStyle {
        switch currentStep {
        case .selectBackupCards: return .grayAlt
        default: return .green
        }
    }
    
    var mainButtonIconName: String {
        switch currentStep {
        case .selectBackupCards:
            return canAddBackupCards ?
                "plus" :
                ""
        default: return ""
        }
    }
    
    var isMainButtonEnabled: Bool {
        switch currentStep {
        case .selectBackupCards: return canAddBackupCards
        default: return true
        }
    }
    
    override var supplementButtonSettings: TangemButtonSettings {
        .init(
            title: supplementButtonTitle,
            size: .wide,
            action: supplementButtonAction,
            isBusy: false,
            isEnabled: isSupplementButtonEnabled,
            isVisible: isSupplementButtonVisible,
            color: supplementButtonColor
        )
    }
    
    var isSupplementButtonEnabled: Bool {
        switch currentStep {
        case .selectBackupCards: return backupCardsAddedCount > 0
        default: return true
        }
    }
    
    var supplementButtonColor: ButtonColorStyle {
        switch currentStep {
        case .selectBackupCards: return .green
        default: return .transparentWhite
        }
    }
    
    var backupCardsAddedCount: Int {
        if assembly?.isPreview ?? false {
            return previewBackupCardsAdded
        }
        
        return backupService.addedBackupCardsCount
    }
    
    private var canAddBackupCards: Bool {
        if assembly?.isPreview ?? false {
            return previewBackupCardsAdded < 2
        }
        
        return backupService.canAddBackupCards
    }
    
    @Published private var previewBackupCardsAdded: Int = 0
    
    private let tangemSdk: TangemSdk
    
    init(input: OnboardingInput, backupService: BackupService, tangemSdk: TangemSdk) {
        self.backupService = backupService
        // [REDACTED_TODO_COMMENT]
        mainCardImage =  UIImage(named: "wallet_card")! // input.cardImage
        self.tangemSdk = tangemSdk
        
        super.init(input: input)
        
        if case let .wallet(steps) = input.steps {
            self.steps = steps
        }
        
        
    }
    
    override func setupContainer(with size: CGSize) {
        stackCalculator.setup(for: size,
                              with: CardsStackAnimatorSettings(topCardSize: WalletOnboardingCardLayout.origin.frame(for: .backupCards, containerSize: size),
                                                               topCardOffset: .init(width: 0, height: 1),
                                                               cardsVerticalOffset: 17,
                                                               scaleStep: 0.11,
                                                               opacityStep: 0.25,
                                                               numberOfCards: 3,
                                                               maxCardsInStack: 3))
        fanStackCalculator.setup(for: size,
                                 with: FanStackCalculatorSettings.defaultSettings)
        super.setupContainer(with: size)
    }
    
    override func mainButtonAction() {
        switch currentStep {
        case .welcome:
            isNavBarVisible = true
            goToNextStep()
        case .createWallet:
            createWallet()
        case .scanOriginCard:
            readOriginCard()
        case .backupIntro:
            goToNextStep()
        case .selectBackupCards:
            addBackupCard()
        case .backupCards:
            backupCard()
        case .success:
            goToNextStep()
        }
    }
    
    override func supplementButtonAction() {
        switch currentStep {
        case .createWallet:
            break
        case .backupIntro:
            withAnimation {
                currentStepIndex = steps.count - 1
            }
        case .selectBackupCards:
            if backupCardsAddedCount < 2 {
                let controller = UIAlertController(title: "common_warning".localized, message: "onboarding_alert_message_not_max_backup_cards_added".localized, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "common_continue".localized, style: .default, handler: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.goToNextStep()
                    }
                }))
                controller.addAction(UIAlertAction(title: "onboarding_button_buy_more_cards".localized, style: .default, handler: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.navigation.onboardingWalletToShop = true
                    }
                }))
                controller.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel, handler: { _ in }))
                UIApplication.topViewController?.present(controller, animated: true, completion: nil)
            } else {
                goToNextStep()
            }
            
        default:
            break
        }
    }
    
    override func setupCardsSettings(animated: Bool, isContainerSetup: Bool) {
        switch currentStep {
        case .selectBackupCards:
            mainCardSettings = .init(targetSettings: fanStackCalculator.settingsForCard(at: 0), intermediateSettings: nil)
            var backupCardSettings = fanStackCalculator.settingsForCard(at: 1)
            backupCardSettings.opacity = backupCardsAddedCount >= 1 ? 1 : 0.2
            
            supplementCardSettings = .init(targetSettings: backupCardSettings, intermediateSettings: nil)
            backupCardSettings = fanStackCalculator.settingsForCard(at: 2)
            backupCardSettings.opacity = backupCardsAddedCount >= 2 ? 1 : 0.2
            
            thirdCardSettings = .init(targetSettings: backupCardSettings, intermediateSettings: nil)
        case .backupCards:
            break
        default:
            mainCardSettings = WalletOnboardingCardLayout.origin.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, stackCalculator: stackCalculator, animated: animated)
            supplementCardSettings = WalletOnboardingCardLayout.firstBackup.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, stackCalculator: stackCalculator, animated: animated)
            thirdCardSettings = WalletOnboardingCardLayout.secondBackup.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, stackCalculator: stackCalculator, animated: animated)
        }
    }
    
    override func reset(includeInResetAnim: (() -> Void)? = nil) {
        super.reset {
            self.previewBackupCardsAdded = 0
            self.thirdCardSettings = WelcomeCardLayout.supplementary.cardSettings(at: .welcome, in: self.containerSize, animated: true)
        }
    }
    
    private func updateStep() {
        switch currentStep {
        case .selectBackupCards:
            setupCardsSettings(animated: true, isContainerSetup: false)
        default:
            break
        }
    }
    
    private func createWallet() {
        isMainButtonBusy = true
        if assembly.isPreview {
            previewGoToNextStepDelayed()
            return
        }
        
        stepPublisher = createWalletAndReadOriginCardPublisher()
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print(error)
                }
            }, receiveValue: processOriginCardScan)
    }
    
    private func readOriginCard() {
        isMainButtonBusy = true
        if assembly.isPreview {
            previewGoToNextStepDelayed()
            return
        }
        
        stepPublisher = readOriginCardPublisher()
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to read origin card: \(error)")
                    }
                },
                receiveValue: processOriginCardScan)
    }
    
    private func createWalletAndReadOriginCardPublisher() -> AnyPublisher<Void, Error> {
        let cardId = input.cardModel.cardInfo.card.cardId
        return Deferred {
            Future { [weak self] promise in
                self?.tangemSdk.startSession(with: CreateWalletAndReadOriginCardTask(), cardId: cardId, completion: { result in
                    switch result {
                    case .success(let originCard):
                        self?.backupService.setOriginCard(originCard)
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                })
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func readOriginCardPublisher() -> AnyPublisher<Void, Error> {
        Deferred {
            Future { [weak self] promise in
                self?.backupService.readOriginCard { result in
                    switch result {
                    case .success:
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func processOriginCardScan(_ result: (Void, Notification)) {
        print("Origin card read successfully")
        isMainButtonBusy = false
        goToNextStep()
    }
    
    private func addBackupCard() {
        isMainButtonBusy = true
        if assembly.isPreview {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.previewBackupCardsAdded += 1
                    self.isMainButtonBusy = false
                    self.updateStep()
                }
            }
            return
        }
        
        stepPublisher =
            Deferred {
                Future { [unowned self] promise in
                    self.backupService.addBackupCard { result in
                        switch result {
                        case .success:
                            promise(.success(()))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                }
            }
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .sink(receiveCompletion: { completion in
                
            }, receiveValue: { [weak self] (_: Void, _: Notification) in
                self?.updateStep()
                withAnimation {
                    self?.isMainButtonBusy = false
                }
            })
    }
    
    private func validateAccessCode() {
        isMainButtonBusy = true
        if assembly.isPreview {
            previewGoToNextStepDelayed()
        }
    }
    
    private func backupCard() {
        isMainButtonBusy = true
        if assembly.isPreview {
            previewGoToNextStepDelayed()
        }
    }
    
    private func previewGoToNextStepDelayed(_ delay: TimeInterval = 2) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.goToNextStep()
            self.isMainButtonBusy = false
        }
    }
    
}

extension NotificationCenter {
    static var didBecomeActivePublisher: AnyPublisher<Notification, Error> {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
