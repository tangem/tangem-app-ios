//
//  WalletOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk

class WalletOnboardingViewModel: OnboardingViewModel<WalletOnboardingStep>, ObservableObject {
    @Injected(\.cardImageLoader) private var imageLoader: CardImageLoaderProtocol
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding

    @Published var thirdCardSettings: AnimatedViewSettings = .zero
    @Published var canDisplayCardImage: Bool = false

    private var stackCalculator: StackCalculator = .init()
    private var fanStackCalculator: FanStackCalculator = .init()
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
            case .finalizingPrimaryCard: return "onboarding_title_prepare_origin"
            case .finalizingBackupCard(let index): return LocalizedStringKey(stringLiteral: "onboarding_title_backup_card_number".localized(index))
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
        case .success:
            switch backupCardsAddedCount {
            case 0: return "onboarding_subtitle_success_tangem_wallet_onboarding"
            case 1: return "onboarding_subtitle_success_backup_one_card"
            default: return "onboarding_subtitle_success_backup"
            }
        case .backupCards:
            switch backupServiceState {
            case .finalizingPrimaryCard:
                return backupService.primaryCardId.map {
                    LocalizedStringKey(stringLiteral: "onboarding_subtitle_scan_origin_card".localized(CardIdFormatter(style: .lastMasked(4)).string(from: $0)))
                }
                    ?? super.subtitle
            case .finalizingBackupCard(let index):
                let cardId = backupService.backupCardIds[index - 1]
                let formattedCardId = CardIdFormatter(style: .lastMasked(4)).string(from: cardId)
                return LocalizedStringKey(stringLiteral: "onboarding_subtitle_scan_backup_card".localized(formattedCardId))
            default: return super.subtitle
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
            return "onboarding_button_add_backup_card"
        case .backupCards:
            switch backupServiceState {
            case .finalizingPrimaryCard: return "onboarding_button_backup_origin"
            case .finalizingBackupCard(let index): return LocalizedStringKey(stringLiteral: "onboarding_button_backup_card".localized(index))
            default: break
            }
        case .success:
            return input.isStandalone ? "common_continue" : super.mainButtonTitle
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
            return "plus"
        default: return ""
        }
    }

    var isMainButtonEnabled: Bool {
        switch currentStep {
        case .selectBackupCards: return canAddBackupCards
        default: return true
        }
    }

    override var isSupplementButtonVisible: Bool {
        if currentStep == .backupIntro && input.isStandalone {
            return false
        }

        return super.isSupplementButtonVisible
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
        return backupService.addedBackupCardsCount
    }

    var isModal: Bool {
        switch (currentStep, backupServiceState) {
        case (.backupCards, .finalizingBackupCard): return true
        default: return false
        }
    }

    var isInfoPagerVisible: Bool {
        switch currentStep {
        case .backupIntro: return true
        default: return false
        }
    }

    private var primaryCardStackIndex: Int {
        switch backupServiceState {
        case .finalizingBackupCard(let index):
            return backupCardsAddedCount - index + 1
        default: return 0
        }
    }

    private var firstBackupCardStackIndex: Int {
        switch backupServiceState {
        case .finalizingBackupCard(let index):
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
        case .finalizingBackupCard(let index):
            return backupCardsAddedCount - index
        default: return 2
        }
    }

    private var canAddBackupCards: Bool {
        return backupService.canAddBackupCards
    }

    private var backupServiceState: BackupService.State {
        return backupService.currentState
    }

    @Published private var previewBackupCardsAdded: Int = 0
    @Published private var previewBackupState: BackupService.State = .finalizingPrimaryCard

    private var tangemSdk: TangemSdk { tangemSdkProvider.sdk }
    private var backupService: BackupService { backupServiceProvider.backupService }
    private unowned var coordinator: WalletOnboardingRoutable!

    init(input: OnboardingInput, coordinator: WalletOnboardingRoutable) {
        self.coordinator = coordinator
        super.init(input: input, onboardingCoordinator: coordinator)

        if case let .wallet(steps) = input.steps {
            self.steps = steps
        }

        if isFromMain {
            canDisplayCardImage = true
        }

        if case let .cardId(cardId) = input.cardInput { // saved backup
            DispatchQueue.main.async {
                self.loadImageForRestoredbackup(cardId: cardId, cardPublicKey: Data())
            }
        }
    }

    private func loadImageForRestoredbackup(cardId: String, cardPublicKey: Data) {
        imageLoader
            .loadImage(cid: cardId,
                       cardPublicKey: cardPublicKey,
                       artworkInfo: nil)
            .map { $0.image }
            .weakAssign(to: \.cardImage, on: self)
            .store(in: &bag)
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
        case .scanPrimaryCard:
            readPrimaryCard()
        case .backupIntro:
            if NFCUtils.isPoorNfcQualityDevice {
                self.alert = AlertBuilder.makeOldDeviceAlert()
            } else {
                if let disabledLocalizedReason = input.cardInput.cardModel?.getDisabledLocalizedReason(for: .backup) {
                    alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
                } else {
                    goToNextStep()
                }
            }
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
            jumpToLatestStep()
            Analytics.log(.backupLaterTapped)
        case .selectBackupCards:
            if backupCardsAddedCount < 2 {
                let controller = UIAlertController(title: "common_warning".localized, message: "onboarding_alert_message_not_max_backup_cards_added".localized, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "common_continue".localized, style: .default, handler: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.openAccessCode()
                    }
                }))
                controller.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel, handler: { _ in }))
                UIApplication.topViewController?.present(controller, animated: true, completion: nil)
            } else {
                openAccessCode()
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
            let prehideSettings: CardAnimSettings? = backupServiceState == .finalizingPrimaryCard ? nil : stackCalculator.prehideAnimSettings
            mainCardSettings = .init(targetSettings: stackCalculator.cardSettings(at: primaryCardStackIndex),
                                     intermediateSettings: ((primaryCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil))

            supplementCardSettings = .init(targetSettings: stackCalculator.cardSettings(at: firstBackupCardStackIndex),
                                           intermediateSettings: ((firstBackupCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil))

            var settings = stackCalculator.cardSettings(at: secondBackupCardStackIndex)
            settings.opacity = backupCardsAddedCount > 1 ? settings.opacity : 0.0
            thirdCardSettings = .init(targetSettings: settings,
                                      intermediateSettings: ((backupCardsAddedCount > 1 && secondBackupCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil))
        default:
            mainCardSettings = WalletOnboardingCardLayout.origin.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, animated: animated)
            supplementCardSettings = WalletOnboardingCardLayout.firstBackup.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, animated: animated)
            thirdCardSettings = WalletOnboardingCardLayout.secondBackup.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, animated: animated)
        }
    }

    func jumpToLatestStep() {
        withAnimation {
            currentStepIndex = steps.count - 1
            setupCardsSettings(animated: true, isContainerSetup: false)
            fireConfetti()
        }
    }

    override func backButtonAction() {
        switch currentStep {
        case .backupCards:
            if backupServiceState == .finalizingPrimaryCard {
                fallthrough
            }

            alert = AlertBuilder.makeOkGotItAlert(message: "onboarding_backup_exit_warning".localized)
        default:
            if isFromMain {
                onboardingDidFinish()
            } else {
                closeOnboarding()
            }

            backupService.discardIncompletedBackup()
        }
    }

    private func saveAccessCode(_ code: String) {
        do {
            try backupService.setAccessCode(code)
            Analytics.log(backupService.addedBackupCardsCount == 0 ? .cardCodeSave : .backupCardSave)
            Analytics.log(.createAccessCode)
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
                Analytics.log(.backupFinish)
                fireConfetti()
                self.goToNextStep()
            } else {
                setupCardsSettings(animated: true, isContainerSetup: false)
            }
        case .success:
            Analytics.log(.onboardingSuccess)
        default:
            break
        }
    }

    private func createWallet() {
        Analytics.log(.createWalletTapped)
        isMainButtonBusy = true
        if !input.isStandalone {
            AppSettings.shared.cardsStartedActivation.append(input.cardInput.cardId)
        }
        stepPublisher = preparePrimaryCardPublisher()
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    if let cardModel = self?.input.cardInput.cardModel {
                        cardModel.logSdkError(error, action: .preparePrimary)
                    }
                    self?.isMainButtonBusy = false
                    print(error)
                }
                self?.stepPublisher = nil
            }, receiveValue: processPrimaryCardScan)
    }

    private func readPrimaryCard() {
        isMainButtonBusy = true

        stepPublisher = readPrimaryCardPublisher()
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        if let cardModel = self?.input.cardInput.cardModel {
                            cardModel.logSdkError(error, action: .readPrimary)
                        }
                        print("Failed to read origin card: \(error)")
                        self?.isMainButtonBusy = false
                    }
                    self?.stepPublisher = nil
                },
                receiveValue: processPrimaryCardScan)
    }

    private func preparePrimaryCardPublisher() -> AnyPublisher<Void, Error> {
        let cardId = input.cardInput.cardId

        return Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }

                self.tangemSdk.startSession(with: PreparePrimaryCardTask(),
                                            cardId: cardId,
                                            initialMessage: Message(header: nil,
                                                                    body: "initial_message_create_wallet_body".localized)) { [weak self] result in
                    switch result {
                    case .success(let result):
                        self?.addDefaultTokens(for: result.card)

                        if let cardModel = self?.input.cardInput.cardModel {
                            cardModel.update(with: result.card, derivedKeys: result.derivedKeys)
                        }

                        self?.backupService.setPrimaryCard(result.primaryCard)
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func readPrimaryCardPublisher() -> AnyPublisher<Void, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }

                self.backupService.readPrimaryCard(cardId: self.input.cardInput.cardId) { result in
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

    private func processPrimaryCardScan(_ result: (Void, Notification)) {
        isMainButtonBusy = false
        goToNextStep()
    }

    private func addBackupCard() {
        isMainButtonBusy = true
        Analytics.log(.addBackupCard)
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
            .first()
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Failed to add backup card. Reason: \(error)")
                    if let cardModel = self?.input.cardInput.cardModel {
                        cardModel.logSdkError(error, action: .addbackup)
                    }
                    self?.isMainButtonBusy = false
                }
                self?.stepPublisher = nil
            }, receiveValue: { [weak self] (_: Void, _: Notification) in
                self?.updateStep()
                withAnimation {
                    self?.isMainButtonBusy = false
                }
            })
    }

    private func backupCard() {
        isMainButtonBusy = true
        Analytics.log(.backupTapped)
        stepPublisher =
            Deferred {
                Future { [unowned self] promise in
                    self.backupService.proceedBackup { result in
                        switch result {
                        case .success(let updatedCard):
                            if updatedCard.cardId == self.backupService.primaryCardId {
                                self.input.cardInput.cardModel?.update(with: updatedCard)
                            } else { // add tokens for backup cards
                                self.addDefaultTokens(for: updatedCard)
                            }
                            promise(.success(()))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                }
            }
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Failed to proceed backup. Reason: \(error)")
                    if let cardModel = self?.input.cardInput.cardModel {
                        cardModel.logSdkError(error, action: .proceedBackup)
                    }
                    self?.isMainButtonBusy = false
                }
                self?.stepPublisher = nil
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

    private func addDefaultTokens(for card: Card) {
        let config = GenericConfig(card: card)
        CommonTokenItemsRepository(key: card.cardId).append(config.defaultBlockchains)
    }
}

// MARK: - Navigation
extension WalletOnboardingViewModel {
    func openAccessCode() {
        coordinator.openAccessCodeView(callback: saveAccessCode)
    }
}

extension NotificationCenter {
    static var didBecomeActivePublisher: AnyPublisher<Notification, Error> {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
