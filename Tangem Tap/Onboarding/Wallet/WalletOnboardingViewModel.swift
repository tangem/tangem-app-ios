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
    @Published var canDisplayCardImage: Bool = false
    
    private var stackCalculator: StackCalculator = .init()
    private var fanStackCalculator: FanStackCalculator = .init()
    private var bag: Set<AnyCancellable> = []
    private var stepPublisher: AnyCancellable?
    
//    override var isBackButtonVisible: Bool {
//        switch currentStep {
//        case .success: return false
//        default: return super.isBackButtonVisible
//        }
//    }
    
    override var navbarTitle: LocalizedStringKey {
        currentStep.navbarTitle
    }
    
    override var title: LocalizedStringKey {
        switch currentStep {
        case .selectBackupCards:
            switch backupCardsAddedCount {
            case 0: return "onboarding_title_no_backup_cards"
            case 1: return "onboarding_title_one_backup_card"
            default: return "onboarding_title_two_backup_cards"
            }
        case .backupIntro:
            return ""
        case .backupCards:
            switch backupServiceState {
            case .needWriteOriginCard: return "onboarding_title_backup_card \(1)"
            case .needWriteBackupCard(let index): return "onboarding_title_backup_card \(1 + index)"
            default: break
            }
        default: break
        }
        return super.title
    }
    
    override var subtitle: LocalizedStringKey {
        switch currentStep {
        case .selectBackupCards:
            switch backupCardsAddedCount {
            case 0: return "onboarding_subtitle_no_backup_cards"
            case 1: return "onboarding_subtitle_one_backup_card"
            default: return "onboarding_subtitle_two_backup_cards"
            }
        case .backupIntro:
            return ""
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
        case .backupCards:
            switch backupServiceState {
            case .needWriteOriginCard: return "onboarding_button_backup_card \(1)"
            case .needWriteBackupCard(let index): return "onboarding_button_backup_card \(1 + index)"
            default: break
            }
        default: break
        }
        return super.mainButtonTitle
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
    
    var isModal: Bool {
        switch (currentStep, backupServiceState) {
        case (.backupCards, .needWriteBackupCard): return true
        default: return false
        }
    }
    
    var isInfoPagerVisible: Bool {
        switch currentStep {
        case .backupIntro: return true
        default: return false
        }
    }
    
    private var originCardStackIndex: Int {
        switch backupServiceState {
        case .needWriteBackupCard(let index):
            return backupCardsAddedCount - index + 1
        default: return 0
        }
    }
    
    private var firstBackupCardStackIndex: Int {
        switch backupServiceState {
        case .needWriteBackupCard(let index):
            switch index {
            case 1: return 0
            case 2: return 2
            default: return 1
            }
        default: return 1
        }
    }
    
    private var secondBackupCardStackIndex: Int {
        switch backupServiceState {
        case .needWriteBackupCard(let index):
            return backupCardsAddedCount - index
        default: return 2
        }
    }
    
    private var canAddBackupCards: Bool {
        if assembly?.isPreview ?? false {
            return previewBackupCardsAdded < 2
        }
        
        return backupService.canAddBackupCards
    }
    
    private var backupServiceState: BackupService.State {
        if assembly?.isPreview ?? false {
            return previewBackupState
        }
        
        return backupService.currentState
    }
    
    @Published private var previewBackupCardsAdded: Int = 0
    @Published private var previewBackupState: BackupService.State = .needWriteOriginCard
    
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
        
        if isFromMain {
            canDisplayCardImage = true
        }
    }
    
    override func setupContainer(with size: CGSize) {
        stackCalculator.setup(for: size,
                              with: CardsStackAnimatorSettings(topCardSize: WalletOnboardingCardLayout.origin.frame(for: .createWallet, containerSize: size),
                                                               topCardOffset: .init(width: 0, height: 1),
                                                               cardsVerticalOffset: 17,
                                                               scaleStep: 0.11,
                                                               opacityStep: 0.25,
                                                               numberOfCards: 3,
                                                               maxCardsInStack: 3))
        
        let cardSize = WalletOnboardingCardLayout.origin.frame(for: .createWallet, containerSize: size)
        fanStackCalculator.setup(for: size,
                                 with: .init(cardsSize: cardSize,
                                             topCardRotation: 3,
                                             cardRotationStep: -10,
                                             topCardOffset: .init(width: 0, height: 0.103 * size.height),
                                             cardOffsetStep: .init(width: 2, height: -cardSize.height * 0.141),
                                             scaleStep: 0.07,
                                             numberOfCards: 3))
        super.setupContainer(with: size)
    }
    
    override func playInitialAnim(includeInInitialAnim: (() -> Void)? = nil) {
        super.playInitialAnim {
            self.canDisplayCardImage = true
        }
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
                setupCardsSettings(animated: true, isContainerSetup: false)
                shouldFireConfetti = true
            }
        case .selectBackupCards:
            if backupCardsAddedCount < 2 {
                let controller = UIAlertController(title: "common_warning".localized, message: "onboarding_alert_message_not_max_backup_cards_added".localized, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "common_continue".localized, style: .default, handler: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.navigation.onboardingWalletToAccessCode = true
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
                navigation.onboardingWalletToAccessCode = true
            }
            
        default:
            break
        }
    }
    
    override func setupCardsSettings(animated: Bool, isContainerSetup: Bool) {
        let animated = animated && !isContainerSetup
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
            let prehideSettings: CardAnimSettings? = backupServiceState == .needWriteOriginCard ? nil : stackCalculator.prehideAnimSettings
            mainCardSettings = .init(targetSettings: stackCalculator.cardSettings(at: originCardStackIndex),
                                     intermediateSettings: ((originCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil))
            
            supplementCardSettings = .init(targetSettings: stackCalculator.cardSettings(at: firstBackupCardStackIndex),
                                           intermediateSettings: ((firstBackupCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil))
            
            var settings = stackCalculator.cardSettings(at: secondBackupCardStackIndex)
            settings.opacity = backupCardsAddedCount > 1 ? 1.0 : 0.0
            thirdCardSettings = .init(targetSettings: settings,
                                      intermediateSettings: ((backupCardsAddedCount > 1 && secondBackupCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil))
        default:
            mainCardSettings = WalletOnboardingCardLayout.origin.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, animated: animated)
            supplementCardSettings = WalletOnboardingCardLayout.firstBackup.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, animated: animated)
            thirdCardSettings = WalletOnboardingCardLayout.secondBackup.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, animated: animated)
        }
    }
    
    override func reset(includeInResetAnim: (() -> Void)? = nil) {
        super.reset {
            self.previewBackupCardsAdded = 0
            self.previewBackupState = .needWriteOriginCard
            self.thirdCardSettings = WelcomeCardLayout.supplementary.cardSettings(at: .welcome, in: self.containerSize, animated: true)
        }
    }
    
    func backButtonAction() {
        switch currentStep {
        case .backupCards:
            if backupServiceState == .needWriteOriginCard {
                fallthrough
            }
            
            alert = AlertBinder(alert: AlertBuilder.makeOkGotItAlert(message: "onboarding_backup_exit_warning".localized))
        default:
            reset()
        }
    }
    
    func saveAccessCode(_ code: String) {
        navigation.onboardingWalletToAccessCode = false
        do {
            try backupService.setAccessCode(code)
            stackCalculator.setupNumberOfCards(1 + backupCardsAddedCount)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.goToNextStep()
            }
        } catch {
            print("Failed to set access code to backup service. Reason: \(error)")
        }
    }
    
    private func updateStep() {
        switch currentStep {
        case .selectBackupCards:
            setupCardsSettings(animated: true, isContainerSetup: false)
        case .backupCards:
            if backupServiceState == .finished {
                shouldFireConfetti = true
                self.goToNextStep()
            } else {
                setupCardsSettings(animated: true, isContainerSetup: false)
            }
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
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Failed to add backup card. Reason: \(error)")
                    self?.isMainButtonBusy = false
                }
            }, receiveValue: { [weak self] (_: Void, _: Notification) in
                self?.updateStep()
                withAnimation {
                    self?.isMainButtonBusy = false
                }
            })
    }
    
    private func backupCard() {
        isMainButtonBusy = true
        if assembly.isPreview {
            let newPreviewState: BackupService.State
            switch backupServiceState {
            case .needWriteOriginCard:
                newPreviewState = .needWriteBackupCard(index: 0)
            case .needWriteBackupCard(let index):
                switch index {
                case 0:
                    if backupCardsAddedCount == 2 {
                        newPreviewState = .needWriteBackupCard(index: 1)
                    } else {
                        newPreviewState = .finished
                    }
                default:
                    newPreviewState = .finished
                }
            default: newPreviewState = .needWriteOriginCard
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.previewBackupState = newPreviewState
                    self.updateStep()
                    self.isMainButtonBusy = false
                }
            }
            return
//            previewGoToNextStepDelayed()
        }
        
        stepPublisher =
            Deferred {
                Future { [unowned self] promise in
                    self.backupService.proceedBackup { result in
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
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Failed to proceed backup. Reason: \(error)")
                    self?.isMainButtonBusy = false
                }
            } receiveValue: { [weak self] (_: Void, _: Notification) in
                self?.updateStep()
                withAnimation {
                    self?.isMainButtonBusy = false
                }
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
