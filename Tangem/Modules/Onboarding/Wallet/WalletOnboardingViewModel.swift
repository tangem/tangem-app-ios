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
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding
    @Injected(\.saletPayRegistratorProvider) private var saltPayRegistratorProvider: SaltPayRegistratorProviding

    @Published var thirdCardSettings: AnimatedViewSettings = .zero
    @Published var canDisplayCardImage: Bool = false
    @Published var pinText: String = ""

    private var stackCalculator: StackCalculator = .init()
    private var fanStackCalculator: FanStackCalculator = .init()
    private var stepPublisher: AnyCancellable?
    private var prepareTask: PreparePrimaryCardTask? = nil

//    override var isBackButtonVisible: Bool {
//        switch currentStep {
//        case .success: return false
//        default: return super.isBackButtonVisible
//        }
//    }

    override var navbarTitle: LocalizedStringKey {
        currentStep.navbarTitle
    }

    override var title: LocalizedStringKey? {
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

        case .registerWallet, .kycStart, .enterPin, .kycWaiting:
            return nil
        default: break
        }
        return super.title
    }

    override var subtitle: LocalizedStringKey? {
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
        case .registerWallet, .kycStart, .enterPin, .kycWaiting:
            return nil
        default: return super.subtitle
        }
    }

    override var mainButtonSettings: TangemButtonSettings? {
        switch currentStep {
        case .enterPin, .registerWallet, .kycStart, .kycProgress:
            return nil
        default:
            break
        }

        return .init(
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
        case .selectBackupCards, .kycWaiting: return .grayAlt
        default: return .black
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
        case .enterPin: return pinText.count == SaltPayRegistrator.Constants.pinLength
        default: return true
        }
    }

    override var isSupplementButtonVisible: Bool {
        if currentStep == .backupIntro {
            if input.isStandalone {
                return false
            }

            if saltPayRegistratorProvider.registrator != nil {
                return false
            }
        }

        return super.isSupplementButtonVisible
    }

    override var supplementButtonSettings: TangemButtonSettings? {
        return .init(
            title: supplementButtonTitle,
            size: .wide,
            action: supplementButtonAction,
            isBusy: isSupplementButtonBusy,
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
        case .selectBackupCards, .kycWaiting, .enterPin, .registerWallet, .kycStart, .kycProgress: return .black
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

    var isCustomContentVisible: Bool {
        switch currentStep {
        case .enterPin, .registerWallet, .kycStart, .kycProgress, .kycWaiting:
            return true
        default: return false
        }
    }

    var isButtonsVisible: Bool {
        switch currentStep {
        case .kycProgress: return false
        default: return true
        }
    }

    lazy var kycModel: WebViewContainerViewModel? = {
        guard let registrator = saltPayRegistratorProvider.registrator else { return nil }

        return .init(url: registrator.kycURL,
                     title: "",
                     addLoadingIndicator: false,
                     withCloseButton: false,
                     withNavigationBar: false,
                     urlActions: [registrator.kycDoneURL: { [weak self] _ in
                         self?.supplementButtonAction()
                     }])
    }()

    var canShowThirdCardImage: Bool {
        saltPayRegistratorProvider.registrator == nil
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
            DispatchQueue.main.async {
                self.fireConfettiIfNeeded()
            }
        }

        if isFromMain {
            canDisplayCardImage = true
        }

        if case let .cardId(cardId) = input.cardInput { // saved backup
            DispatchQueue.main.async {
                self.loadImageForRestoredbackup(cardId: cardId, cardPublicKey: Data())
            }
        }

        bindSaltPayIfNeeded()
    }

    private func bindSaltPayIfNeeded() {
        guard let saltPayRegistrator = saltPayRegistratorProvider.registrator else { return }

        saltPayRegistrator
            .$error
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.alert, on: self)
            .store(in: &bag)

        saltPayRegistrator
            .$isBusy
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.isSupplementButtonBusy, on: self)
            .store(in: &bag)

        saltPayRegistrator
            .$state
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] newState in
                switch newState {
                case .kycStart:
                    if self?.currentStep == .kycWaiting {
                        break
                    }
                    self?.goToNextStep()
                case .finished:
                    self?.goToNextStep()
                default:
                    break
                }
            })
            .store(in: &bag)
    }

    private func loadImageForRestoredbackup(cardId: String, cardPublicKey: Data) {
        CardImageProvider()
            .loadImage(cardId: cardId, cardPublicKey: cardPublicKey)
            .map { Image(uiImage: $0) }
            .weakAssign(to: \.cardImage, on: self)
            .store(in: &bag)
    }

    override func loadImage(supportsOnlineImage: Bool, cardId: String?, cardPublicKey: Data?) {
        super.loadImage(supportsOnlineImage: supportsOnlineImage, cardId: cardId, cardPublicKey: cardPublicKey)
        if saltPayRegistratorProvider.registrator == nil {
            secondImage = nil
        } else {
            let isPrimaryScanned = cardId.map { !SaltPayUtil().isBackupCard(cardId: $0) } ?? false
            secondImage = isPrimaryScanned ? Assets.saltPayBackup : Assets.saltpay
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
        case .scanPrimaryCard:
            readPrimaryCard()
        case .backupIntro:
            Analytics.log(.backupScreenOpened)
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
        case .kycWaiting:
            openSupportChat()
        default:
            break
        }
    }

    override func supplementButtonAction() {
        switch currentStep {
        case .createWallet:
            break
        case .backupIntro:
            Analytics.log(.backupSkipped)
            jumpToLatestStep()
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
        case .kycWaiting:
            saltPayRegistratorProvider.registrator?.update()
        case .enterPin:
            saltPayRegistratorProvider.registrator?.setPin(pinText)
            goToNextStep()
        case .registerWallet:
            saltPayRegistratorProvider.registrator?.register()
        case .kycStart:
            goToNextStep()
        case .kycProgress:
            goToNextStep()
            saltPayRegistratorProvider.registrator?.onFinishKYC()
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

    override func goToNextStep() {
        super.goToNextStep()

        switch currentStep {
        case .success:
            withAnimation {
                fireConfetti()
            }
        default:
            break
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

    private func fireConfettiIfNeeded() {
        if currentStep.isOnboardingFinished {
            fireConfetti()
        }
    }

    private func saveAccessCode(_ code: String) {
        do {
            try backupService.setAccessCode(code)
            saltPayRegistratorProvider.registrator?.setAccessCode(code)
            Analytics.log(.settingAccessCodeStarted)
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
                Analytics.log(.backupFinished)
                self.goToNextStep()
            } else {
                setupCardsSettings(animated: true, isContainerSetup: false)
            }
        case .success:
            Analytics.log(.onboardingFinished)
        default:
            break
        }
    }

    private func createWallet() {
        Analytics.log(.buttonCreateWallet)
        Analytics.log(.createWalletScreenOpened)

        isMainButtonBusy = true
        if !input.isStandalone {
            AppSettings.shared.cardsStartedActivation.insert(input.cardInput.cardId)
        }
        stepPublisher = preparePrimaryCardPublisher()
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .mapVoid()
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
            .mapVoid()
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
        let task = PreparePrimaryCardTask()
        prepareTask = task

        return Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }

                self.tangemSdk.startSession(with: task,
                                            cardId: cardId,
                                            initialMessage: Message(header: nil,
                                                                    body: "initial_message_create_wallet_body".localized)) { [weak self] result in
                    switch result {
                    case .success(let result):
                        self?.addDefaultTokens(for: result.card)

                        if let cardModel = self?.input.cardInput.cardModel {
                            cardModel.update(with: result.card)
                        }

                        self?.backupService.setPrimaryCard(result.primaryCard)
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }

                    self?.prepareTask = nil
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

    private func processPrimaryCardScan() {
        isMainButtonBusy = false
        goToNextStep()
    }

    private func addBackupCard() {
        isMainButtonBusy = true
        Analytics.log(.backupStarted)
        Analytics.log(.backupScreenOpened)
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
        Analytics.log(.buttonCreateBackup)
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
        let repository = CommonTokenItemsRepository(key: card.userWalletId.hexString)
        repository.append(config.defaultBlockchains)
    }
}

// MARK: - Navigation
extension WalletOnboardingViewModel {
    func openAccessCode() {
        coordinator.openAccessCodeView(callback: saveAccessCode)
    }

    func openSupportChat() {
        guard let cardModel = input.cardInput.cardModel else { return }

        let dataCollector = DetailsFeedbackDataCollector(cardModel: cardModel,
                                                         userWalletEmailData: cardModel.emailData)

        coordinator.openSupportChat(cardId: cardModel.cardId,
                                    dataCollector: dataCollector)
    }
}

extension NotificationCenter {
    static var didBecomeActivePublisher: AnyPublisher<Notification, Error> {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
