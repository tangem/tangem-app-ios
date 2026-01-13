//
//  WalletOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import Combine
import CombineExt
import TangemSdk
import BlockchainSdk
import TangemFoundation
import TangemUI
import TangemMobileWalletSdk
import struct TangemSdk.Mnemonic
import struct TangemUIUtils.AlertBinder

class WalletOnboardingViewModel: OnboardingViewModel<WalletOnboardingStep, OnboardingCoordinator>, ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let seedPhraseManager = SeedPhraseManager()

    @Published var thirdCardSettings: AnimatedViewSettings = .zero
    @Published var canDisplayCardImage: Bool = false

    var primaryLabel: String {
        if backupService.isPrimaryRing {
            Localization.commonOriginRing
        } else {
            Localization.commonOriginCard
        }
    }

    private var stackCalculator: StackCalculator = .init()
    private var fanStackCalculator: FanStackCalculator = .init()
    private var accessCode: String?
    private var cardIds: Set<String>?
    private var stepPublisher: AnyCancellable?

    private var isPrimaryCardRing: Bool {
        // Case for scanning a card with created wallets. Scan primary card state
        // Workaround by cardId.
        let batchId = String(input.primaryCardId.prefix(8))
        return RingUtil().isRing(batchId: batchId)
    }

    private var cardIdDisplayFormat: CardIdDisplayFormat = .lastMasked(4)

    override var navbarTitle: String {
        currentStep.navbarTitle
    }

    // MARK: - Title settings

    override var title: String? {
        switch currentStep {
        case .selectBackupCards:
            switch backupCardsAddedCount {
            case 0: return Localization.onboardingTitleNoBackupCards
            case 1: return Localization.onboardingTitleOneBackupCard
            default: return Localization.onboardingTitleTwoBackupCards
            }
        case .backupIntro:
            return ""
        case .backupCards:
            switch backupServiceState {
            case .finalizingPrimaryCard: return backupService.isPrimaryRing ? Localization.commonOriginRing : Localization.commonOriginCard
            case .finalizingBackupCard:
                return backupService.isFinalizingRing ? Localization.onboardingTitleBackupRing :
                    Localization.onboardingTitleBackupCard
            default: break
            }
        default: break
        }
        return super.title
    }

    // MARK: - Subtitle

    override var subtitle: String? {
        switch currentStep {
        case .selectBackupCards:
            switch backupCardsAddedCount {
            case 0: return Localization.onboardingSubtitleNoBackupCards
            case 1: return Localization.onboardingSubtitleOneBackupCard
            default: return Localization.onboardingSubtitleTwoBackupCards
            }
        case .backupIntro:
            return ""
        case .success:
            return Localization.onboardingSubtitleSuccessTangemWalletOnboarding
        case .backupCards:
            switch backupServiceState {
            case .finalizingPrimaryCard:
                if backupService.isFinalizingRing {
                    return Localization.onboardingSubtitleScanRing
                }

                guard let primaryCardId = backupService.primaryCard?.cardId,
                      let cardIdFormatted = CardIdFormatter(style: cardIdDisplayFormat).string(from: primaryCardId) else {
                    return super.subtitle
                }

                return Localization.onboardingSubtitleScanPrimaryCardFormat(cardIdFormatted)
            case .finalizingBackupCard(let index):
                if backupService.isFinalizingRing {
                    return Localization.onboardingSubtitleScanRing
                }

                let backupCardIds = backupService.backupCards.map { $0.cardId }
                let cardId = backupCardIds[index - 1]
                guard let cardIdFormatted = CardIdFormatter(style: cardIdDisplayFormat).string(from: cardId) else {
                    return super.subtitle
                }

                return Localization.onboardingSubtitleScanBackupCardFormat(cardIdFormatted)
            default: return super.subtitle
            }
        default: return super.subtitle
        }
    }

    // MARK: - Main Button setup

    override var mainButtonSettings: MainButton.Settings? {
        switch currentStep {
        case .createWallet, .pushNotifications, .seedPhraseIntro, .backupCards, .success, .scanPrimaryCard, .mobileUpgradeIntro:
            return nil
        default:
            return MainButton.Settings(
                title: mainButtonTitle,
                icon: mainButtonIcon,
                style: mainButtonStyle,
                isLoading: isMainButtonBusy,
                isDisabled: !isMainButtonEnabled,
                action: mainButtonAction
            )
        }
    }

    override var mainButtonTitle: String {
        switch currentStep {
        case .selectBackupCards:
            return Localization.onboardingButtonAddBackupCard
        case .success:
            return input.isStandalone ? Localization.commonContinue : super.mainButtonTitle
        default: break
        }
        return super.mainButtonTitle
    }

    var mainButtonStyle: MainButton.Style {
        switch currentStep {
        case .selectBackupCards: return .secondary
        default: return .primary
        }
    }

    var isMainButtonEnabled: Bool {
        switch currentStep {
        case .selectBackupCards: return canAddBackupCards
        default: return true
        }
    }

    // MARK: - Supplement Button settings

    override var supplementButtonTitle: String {
        switch currentStep {
        case .backupCards:
            switch backupServiceState {
            case .finalizingPrimaryCard, .finalizingBackupCard:
                return backupService.isFinalizingRing ? Localization.onboardingButtonBackupRing : Localization.onboardingButtonBackupCard
            default: break
            }
        case .success:
            return input.isStandalone ? Localization.commonContinue : super.supplementButtonTitle
        default: break
        }

        return super.supplementButtonTitle
    }

    override var supplementButtonStyle: MainButton.Style {
        switch currentStep {
        case .createWallet, .selectBackupCards, .scanPrimaryCard, .backupCards, .success, .mobileUpgradeIntro:
            return .primary
        default:
            return .secondary
        }
    }

    override var isSupplementButtonEnabled: Bool {
        switch currentStep {
        case .selectBackupCards: return backupCardsAddedCount > 0
        default: return true
        }
    }

    // MARK: -

    var infoText: String? {
        currentStep.infoText
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
        case .saveUserWallet, .pushNotifications, .seedPhraseIntro, .seedPhraseGeneration, .seedPhraseUserValidation, .seedPhraseImport, .addTokens, .mobileUpgradeBiometrics:
            return true
        default: return false
        }
    }

    // MARK: - Other View related stuff

    override var isSupportButtonVisible: Bool {
        if case .success = currentStep {
            return false
        }

        return true
    }

    lazy var importSeedPhraseModel: OnboardingSeedPhraseImportViewModel? = .init(
        inputProcessor: SeedPhraseInputProcessor(),
        shouldShowTangemIcon: true,
        delegate: self
    )
    var generateSeedPhraseModel: OnboardingSeedPhraseGenerateViewModel?
    var validationUserSeedPhraseModel: OnboardingSeedPhraseUserValidationViewModel?

    var canShowThirdCardImage: Bool {
        return true
    }

    var canShowOriginCardLabel: Bool {
        return currentStep == .backupCards
    }

    // MARK: - Private properties

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

    private lazy var mobileSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let backupService: BackupService
    private var cardInitializer: CardInitializer?
    private var resetCardSetUtil: ResetToFactoryUtil?
    private let backupValidator = BackupValidator()

    // MARK: - Initializer

    override init(input: OnboardingInput, coordinator: OnboardingCoordinator) {
        backupService = input.backupService
        cardIds = input.backupService.allCardIds
        cardInitializer = input.cardInitializer

        super.init(input: input, coordinator: coordinator)

        if case .wallet(let steps) = input.steps {
            self.steps = steps
            DispatchQueue.main.async {
                self.fireConfettiIfNeeded()
            }
        }

        if isFromMain {
            canDisplayCardImage = true
        }

        bind()
    }

    func onAppear() {
        if isInitialAnimPlayed {
            return
        }

        playInitialAnim()
    }

    private func bind() {
        $currentStepIndex
            .removeDuplicates()
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .receiveValue { [weak self] index in
                guard let steps = self?.steps,
                      index < steps.count else { return }

                let currentStep = steps[index]

                switch currentStep {
                case .success:
                    withAnimation {
                        self?.fireConfetti()
                    }
                default:
                    break
                }
            }
            .store(in: &bag)

        subscribeToScreenshots()
    }

    override func setupContainer(with size: CGSize) {
        stackCalculator.setup(
            for: size,
            with: CardsStackAnimatorSettings(
                topCardSize: WalletOnboardingCardLayout.origin.frame(for: .createWallet, containerSize: size),
                topCardOffset: .init(width: 0, height: 1),
                cardsVerticalOffset: 17,
                scaleStep: 0.11,
                opacityStep: 0.25,
                numberOfCards: 3,
                maxCardsInStack: 3
            )
        )

        let cardSize = WalletOnboardingCardLayout.origin.frame(for: .createWallet, containerSize: size)
        fanStackCalculator.setup(
            for: size,
            with: .init(
                cardsSize: cardSize,
                topCardRotation: 3,
                cardRotationStep: -10,
                topCardOffset: .init(width: 0, height: 0.103 * size.height),
                cardOffsetStep: .init(width: 2, height: -cardSize.height * 0.141),
                scaleStep: 0.07,
                numberOfCards: 3
            )
        )
        super.setupContainer(with: size)
    }

    override func playInitialAnim(includeInInitialAnim: (() -> Void)? = nil) {
        super.playInitialAnim {
            self.canDisplayCardImage = true
        }
    }

    override func goToNextStep() {
        if currentStep.isCreateWalletStep,
           let backupIntroStepIndex = steps.firstIndex(where: { $0.isInitialBackupStep }) {
            goToStep(with: backupIntroStepIndex)
            return
        }

        super.goToNextStep()
    }

    // MARK: - Main button action

    override func mainButtonAction() {
        switch currentStep {
        case .createWalletSelector:
            createWallet()
        case .seedPhraseGeneration:
            goToStep(.seedPhraseUserValidation)
        case .backupIntro:
            if NFCUtils.isPoorNfcQualityDevice {
                alert = AlertBuilder.makeOldDeviceAlert()
            } else {
                if let disabledLocalizedReason = input.cardInput.demoBackupDisabledLocalizedReason {
                    alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
                } else {
                    goToNextStep()
                }
            }
        case .selectBackupCards:
            addBackupCard()
        default:
            break
        }
    }

    // MARK: - Supplement button action

    override func supplementButtonAction() {
        switch currentStep {
        case .createWallet:
            createWallet()
        case .createWalletSelector:
            logAnalytics(.onboardingSeedButtonOtherCreateWalletOptions)
            goToStep(.seedPhraseIntro)
        case .seedPhraseIntro:
            logAnalytics(.onboardingSeedButtonImportWallet)
            importSeedPhraseModel?.resetModel()
            goToStep(.seedPhraseImport)
        case .backupIntro:
            logAnalytics(.backupSkipped)
            if steps.contains(.saveUserWallet) {
                goToStep(.saveUserWallet)
            } else if steps.contains(.addTokens) {
                goToStep(.addTokens)
            } else {
                jumpToLatestStep()
            }
        case .selectBackupCards:
            if canAddBackupCards {
                let controller = UIAlertController(title: Localization.commonWarning, message: Localization.onboardingAlertMessageNotMaxBackupCardsAdded, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: Localization.commonContinue, style: .default, handler: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.openAccessCode()
                    }
                }))
                controller.addAction(UIAlertAction(title: Localization.commonCancel, style: .cancel, handler: { _ in }))
                UIApplication.topViewController?.present(controller, animated: true, completion: nil)
            } else {
                openAccessCode()
            }
        case .backupCards:
            backupCard()
        case .success:
            goToNextStep()
        case .scanPrimaryCard:
            readPrimaryCard()
        case .mobileUpgradeIntro:
            upgradeMobileWallet()
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
            mainCardSettings = .init(
                targetSettings: stackCalculator.cardSettings(at: primaryCardStackIndex),
                intermediateSettings: (primaryCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil
            )

            supplementCardSettings = .init(
                targetSettings: stackCalculator.cardSettings(at: firstBackupCardStackIndex),
                intermediateSettings: (firstBackupCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil
            )

            var settings = stackCalculator.cardSettings(at: secondBackupCardStackIndex)
            settings.opacity = backupCardsAddedCount > 1 ? settings.opacity : 0.0
            thirdCardSettings = .init(
                targetSettings: settings,
                intermediateSettings: (backupCardsAddedCount > 1 && secondBackupCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil
            )
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
        case .seedPhraseIntro:
            goToStep(.createWalletSelector)
        case .seedPhraseGeneration:
            goToStep(.seedPhraseIntro)
        case .seedPhraseImport:
            UIApplication.shared.endEditing()
            goToStep(.seedPhraseIntro)
        case .seedPhraseUserValidation:
            goToStep(.seedPhraseGeneration)
        case .backupCards:
            if backupServiceState == .finalizingPrimaryCard {
                fallthrough
            }

            alert = AlertBuilder.makeOkGotItAlert(message: Localization.onboardingBackupExitWarning)
        default:
            alert = AlertBuilder.makeExitAlert { [weak self] in
                self?.back()
            }
        }
    }

    override func didAskToSaveUserWallets(agreed: Bool) {
        super.didAskToSaveUserWallets(agreed: agreed)
        trySaveAccessCodes()
    }

    private func back() {
        closeOnboarding()

        backupService.discardIncompletedBackup()
    }

    private func fireConfettiIfNeeded() {
        if currentStep.requiresConfetti {
            fireConfetti()
        }
    }

    private func saveAccessCode(_ code: String) {
        do {
            try backupService.setAccessCode(code)

            accessCode = code
            cardIds = backupService.allCardIds

            stackCalculator.setupNumberOfCards(1 + backupCardsAddedCount)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.goToNextStep()
            }
        } catch {
            AppLogger.error("Failed to set access code to backup service", error: error)
        }
    }

    private func updateStep() {
        switch currentStep {
        case .selectBackupCards:
            setupCardsSettings(animated: true, isContainerSetup: false)
        case .backupCards:
            if backupServiceState == .finished {
                goToNextStep()
            } else {
                setupCardsSettings(animated: true, isContainerSetup: false)
            }
        default:
            break
        }
    }

    private func createWallet() {
        logAnalytics(.buttonCreateWallet)

        isMainButtonBusy = true

        createWalletOnPrimaryCard(using: nil, mnemonicPassphrase: nil, walletCreationType: .privateKey)
    }

    private func upgradeMobileWallet() {
        guard let context = input.mobileContext else {
            return
        }

        do {
            let mnemonicPhrase = try mobileSdk.exportMnemonic(context: context).joined(separator: " ")
            let mnemonic = try Mnemonic(with: mnemonicPhrase)
            let mnemonicPassphrase = try mobileSdk.exportPassphrase(context: context)

            isSupplementButtonBusy = true

            createWalletOnPrimaryCard(
                using: mnemonic,
                mnemonicPassphrase: mnemonicPassphrase,
                walletCreationType: .seedImport(
                    length: mnemonicPhrase.count,
                    isWithPassphrase: mnemonicPassphrase.isNotEmpty
                )
            )

        } catch {
            isSupplementButtonBusy = false
            alert = error.alertBinder
        }
    }

    private func readPrimaryCard() {
        isMainButtonBusy = true

        stepPublisher = readPrimaryCardPublisher()
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .mapToVoid()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        AppLogger.error("Failed to read origin card", error: error)
                        Analytics.error(error: error, params: [.action: .readPrimary])
                        self?.isMainButtonBusy = false
                    }
                    self?.stepPublisher = nil
                },
                receiveValue: { [weak self] in
                    self?.processPrimaryCardScan()
                }
            )
    }

    private func createWalletOnPrimaryCard(using mnemonic: Mnemonic? = nil, mnemonicPassphrase passphrase: String?, walletCreationType: WalletCreationType) {
        guard let cardInitializer else { return }

        AppSettings.shared.cardsStartedActivation.insert(input.primaryCardId)

        cardInitializer.initializeCard(mnemonic: mnemonic, passphrase: passphrase) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let cardInfo):
                initializeUserWallet(from: cardInfo)

                if let primaryCard = cardInfo.primaryCard {
                    backupService.setPrimaryCard(primaryCard)
                }

                logAnalytics(event: .walletCreatedSuccessfully, params: walletCreationType.params)
                processPrimaryCardScan()
            case .failure(let error):
                if !error.toTangemSdkError().isUserCancelled {
                    AppLogger.error(error: error)
                    Analytics.error(error: error, params: [.action: .preparePrimary])

                    if case TangemSdkError.walletAlreadyCreated = error {
                        alert = AlertBuilder.makeAlert(
                            title: Localization.onboardingActivationErrorTitle,
                            message: Localization.onboardingActivationErrorMessage,
                            primaryButton: .default(Text(Localization.warningButtonOk), action: { [weak self] in
                                self?.cardInitializer?.shouldReset = true
                            }),
                            secondaryButton: .default(Text(Localization.commonSupport), action: { [weak self] in
                                self?.openSupport()
                            })
                        )
                    } else {
                        alert = error.alertBinder
                    }
                }
            }

            isMainButtonBusy = false
            isSupplementButtonBusy = false
        }
    }

    private func readPrimaryCardPublisher() -> AnyPublisher<Void, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }

                // Ring onboarding. Set custom image for ring.
                backupService.config.setupForProduct(isPrimaryCardRing ? .ring : .card)
                backupService.readPrimaryCard(cardId: input.primaryCardId) { result in
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

        stepPublisher =
            Deferred {
                Future { [weak self] promise in
                    self?.backupService.addBackupCard { result in
                        switch result {
                        case .success(let card):
                            promise(.success(card))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                }
            }
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.processBackupError(error)
                    self?.isMainButtonBusy = false
                }
                self?.stepPublisher = nil
            }, receiveValue: { [weak self] card, _ in
                self?.loadImage(for: card)
                self?.updateStep()
                withAnimation {
                    self?.isMainButtonBusy = false
                }
            })
    }

    private func loadImage(for card: Card) {
        switch backupService.addedBackupCardsCount {
        case 1:
            loadSecondImage(card: card)
        case 2:
            loadThirdImage(card: card)
        default:
            break
        }
    }

    private func backupCard() {
        // Sometimes a step state does not update for an unknown reason.
        if backupServiceState == .finished {
            goToNextStep()
            return
        }

        isMainButtonBusy = true

        let ringUtil = RingUtil()

        // Ring onboarding. Set custom image for ring
        backupService.config.setupForProduct(backupService.isFinalizingRing ? .ring : .card)

        let containsRing = backupService.allBatchIds.contains(where: { ringUtil.isRing(batchId: $0) })

        stepPublisher =
            Deferred {
                Future { [weak self] promise in
                    guard let self else { return }

                    backupService.proceedBackup { [weak self] result in
                        guard let self else { return }

                        // Ring onboarding. Reset to defaults
                        backupService.config.setupForProduct(.any)

                        switch result {
                        case .success(let updatedCard):
                            guard backupValidator.onProceedBackup(updatedCard) else {
                                alert = makeResetCardSetAlert()
                                return
                            }

                            if backupServiceState == .finished {
                                // Ring onboarding. Save userWalletId with ring, except interrupted backups
                                if containsRing,
                                   let userWalletId = userWalletModel?.userWalletId.stringValue {
                                    AppSettings.shared.userWalletIdsWithRing.insert(userWalletId)
                                }

                                trySaveAccessCodes()

                                backupValidator.onBackupCompleted()

                                let backupedUserWalletModel: UserWalletModel?
                                switch userWalletModel {
                                case .some(let model):
                                    backupedUserWalletModel = model
                                case .none:
                                    // Used during mobile-to-hardware wallet upgrade when the backup flow
                                    // was interrupted. In this case we need to locate the corresponding
                                    // UserWalletModel by deriving its userWalletId from the card's public key.
                                    let cardInfo = CardInfo(card: CardDTO(card: updatedCard), walletData: .none, associatedCardIds: [])
                                    if let userWalletId = UserWalletId(cardInfo: cardInfo) {
                                        backupedUserWalletModel = userWalletRepository.models[userWalletId]
                                    } else {
                                        backupedUserWalletModel = nil
                                    }
                                }

                                backupedUserWalletModel?.update(type: .backupCompleted(card: updatedCard, associatedCardIds: cardIds ?? []))
                                logAnalytics(
                                    event: .backupFinished,
                                    params: [.cardsCount: String((updatedCard.backupStatus?.backupCardsCount ?? 0) + 1)]
                                )
                            }

                            promise(.success(()))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                }
            }
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }

                if case .failure(let error) = completion {
                    AppLogger.error(error: error)

                    let sdkError = error.toTangemSdkError()
                    if !sdkError.isUserCancelled {
                        alert = sdkError.alertBinder
                        Analytics.logScanError(error, source: .backup, contextParams: getContextParams())
                    }

                    isMainButtonBusy = false
                }
                stepPublisher = nil
            } receiveValue: { [weak self] (_: Void, _: Notification) in
                self?.updateStep()
                withAnimation {
                    self?.isMainButtonBusy = false
                }
            }
    }

    private func trySaveAccessCodes() {
        guard
            let accessCode = accessCode,
            let cardIds = cardIds
        else {
            return
        }

        AccessCodeSaveUtility().trySave(accessCode: accessCode, cardIds: cardIds)
    }

    private func processBackupError(_ error: Error) {
        AppLogger.error(error: error)
        Analytics.error(error: error, params: [.action: .addbackup])

        if let tangemSdkError = error as? TangemSdkError,
           case .backupFailedNotEmptyWallets(let cardId) = tangemSdkError {
            requestResetCard(with: cardId)
            return
        }

        let sdkError = error.toTangemSdkError()
        if !sdkError.isUserCancelled {
            alert = sdkError.alertBinder
        }
    }

    private func requestResetCard(with cardId: String) {
        alert = AlertBuilder.makeAlert(
            title: Localization.commonAttention,
            message: Localization.onboardingLinkingErrorCardWithWallets,
            primaryButton: .destructive(Text(Localization.cardSettingsActionSheetReset), action: { [weak self] in
                self?.resetCard(with: cardId)
            }),
            secondaryButton: .default(Text(Localization.commonCancel)) { [weak self] in
                self?.logAnalytics(.backupResetCardNotification, params: [.option: .cancel])
            }
        )
    }

    private func resetCard(with cardId: String) {
        logAnalytics(.backupResetCardNotification, params: [.option: .reset])
        isMainButtonBusy = true

        let interactor = FactorySettingsResettingCardInteractor(with: cardId)
        interactor.resetCard { [weak self] result in
            switch result {
            case .failure(let error):
                if error.isUserCancelled {
                    break
                }

                self?.alert = error.alertBinder
            case .success:
                break
            }

            self?.isMainButtonBusy = false
            withExtendedLifetime(interactor) {}
        }
    }

    private func loadSecondImage(card: Card) {
        runTask(in: self) { model in
            let imageProvider = CardImageProvider(card: CardDTO(card: card))
            let imageValue = await imageProvider.loadLargeImage()

            await runOnMain {
                withAnimation {
                    model.secondImage = imageValue.image
                }
            }
        }
    }

    private func loadThirdImage(card: Card) {
        runTask(in: self) { model in
            let imageProvider = CardImageProvider(card: CardDTO(card: card))
            let imageValue = await imageProvider.loadLargeImage()

            await runOnMain {
                withAnimation {
                    model.thirdImage = imageValue.image
                }
            }
        }
    }

    private func ensureWalletIsNotAlreadyAdded(mnemonic: Mnemonic, passphrase: String) throws {
        let curve = EllipticCurve.secp256k1

        let masterKeyFactory = AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: passphrase)
        let extendedPrivateKey = try masterKeyFactory.makeMasterKey(for: curve)
        let extendedPublicKey = try extendedPrivateKey.makePublicKey(for: curve)
        let publicKeyData = extendedPublicKey.publicKey
        let userWalletId = UserWalletId(with: publicKeyData)

        guard !userWalletRepository.models.contains(where: { $0.userWalletId == userWalletId }) else {
            throw UserWalletRepositoryError.duplicateWalletAdded
        }
    }
}

// MARK: - Seed phrase related

extension WalletOnboardingViewModel {
    func openReadMoreAboutSeedPhraseScreen() {
        let baseUrl = AppEnvironment.current.tangemComBaseUrl
        let url = baseUrl.appendingPathComponent("seed-phrase-\(Locale.webLanguageCode()).html")
        coordinator?.openWebView(with: url)
        logAnalytics(.onboardingSeedButtonReadMore)
    }

    func generateSeedPhrase() {
        logAnalytics(.onboardingSeedButtonGenerateSeedPhrase)
        do {
            try seedPhraseManager.generateSeedPhrase()
            generateSeedPhraseModel = .init(seedPhraseManager: seedPhraseManager, delegate: self)
            goToNextStep()
        } catch {
            alert = error.alertBinder
        }
    }

    private func subscribeToScreenshots() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .filter { [weak self] _ in
                guard let self else { return false }
                switch currentStep {
                case .seedPhraseGeneration, .seedPhraseUserValidation, .seedPhraseImport:
                    return true
                default:
                    return false
                }
            }
            .sink { [weak self] _ in
                self?.alert = AlertBuilder.makeOkGotItAlert(message: Localization.onboardingSeedScreenshotAlert)
                self?.logAnalytics(.onboardingSeedScreenCapture)
            }
            .store(in: &bag)
    }
}

// MARK: - Backup card validation and resetting flow

private extension WalletOnboardingViewModel {
    func makeResetCardSetAlert() -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.resetCardsDialogFirstTitle,
            message: Localization.resetCardsDialogFirstDescription,
            primaryButton: .destructive(
                Text(Localization.commonReset),
                action: { [weak self] in
                    self?.resetCardSet()
                }
            ),
            secondaryButton: .default(
                Text(Localization.commonCancel),
                action: weakify(self, forFunction: WalletOnboardingViewModel.onDidFinishResetCardSet)
            )
        )
    }

    func resetCardSet() {
        var cardInteractors: [FactorySettingsResetting] = []

        if let primaryCardId = backupService.primaryCard?.cardId {
            cardInteractors.append(FactorySettingsResettingCardInteractor(with: primaryCardId))
        }

        backupService.backupCards.forEach {
            cardInteractors.append(FactorySettingsResettingCardInteractor(with: $0.cardId))
        }

        let resetUtil = ResetToFactoryUtilBuilder().build(cardInteractors: cardInteractors)

        resetUtil.alertPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, alert in
                viewModel.alert = alert
            }
            .store(in: &bag)

        resetUtil.resetToFactory(onDidFinish: weakify(self, forFunction: WalletOnboardingViewModel.onDidFinishResetCardSet))

        resetCardSetUtil = resetUtil
    }

    func onDidFinishResetCardSet() {
        backupService.discardIncompletedBackup()
        backupValidator.onBackupCompleted()
        closeOnboarding()
    }
}

extension WalletOnboardingViewModel: OnboardingSeedPhraseGenerationDelegate {
    func continuePhraseGeneration(with entropyLength: EntropyLength) {
        guard let mnemonic = seedPhraseManager.mnemonics[entropyLength] else {
            alert = MnemonicError.mnenmonicCreationFailed.alertBinder
            return
        }

        let words = mnemonic.mnemonicComponents
        guard words.count == entropyLength.wordCount else {
            alert = MnemonicError.invalidWordCount.alertBinder
            return
        }

        validationUserSeedPhraseModel = OnboardingSeedPhraseUserValidationViewModel(
            mode: .card,
            validationInput: .init(
                secondWord: words[1],
                seventhWord: words[6],
                eleventhWord: words[10],
                createWalletAction: { [weak self, mnemonic] in
                    self?.createWalletOnPrimaryCard(using: mnemonic, mnemonicPassphrase: nil, walletCreationType: .newSeed)
                }
            )
        )
        mainButtonAction()
    }
}

extension WalletOnboardingViewModel: SeedPhraseImportDelegate {
    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String) {
        Analytics.log(.onboardingSeedButtonImport)

        do {
            try ensureWalletIsNotAlreadyAdded(mnemonic: mnemonic, passphrase: passphrase)

            let isWithPassphrase = !passphrase.isEmpty
            createWalletOnPrimaryCard(
                using: mnemonic,
                mnemonicPassphrase: passphrase,
                walletCreationType: .seedImport(
                    length: mnemonic.mnemonicComponents.count,
                    isWithPassphrase: isWithPassphrase
                )
            )
        } catch {
            alert = error.alertBinder
        }
    }
}

// MARK: - Wallet creation type

extension WalletOnboardingViewModel {
    enum WalletCreationType {
        case privateKey
        case newSeed
        case seedImport(length: Int, isWithPassphrase: Bool)

        var params: [Analytics.ParameterKey: String] {
            switch self {
            case .privateKey:
                return [.creationType: Analytics.ParameterValue.walletCreationTypePrivateKey.rawValue]
            case .newSeed:
                return [.creationType: Analytics.ParameterValue.walletCreationTypeNewSeed.rawValue]
            case .seedImport(let length, let isWithPassphrase):
                return [
                    .creationType: Analytics.ParameterValue.walletCreationTypeSeedImport.rawValue,
                    .seedLength: "\(length)",
                    .passphrase: isWithPassphrase ? Analytics.ParameterValue.full.rawValue : Analytics.ParameterValue.empty.rawValue,
                ]
            }
        }
    }
}

// MARK: - Navigation

extension WalletOnboardingViewModel {
    func openAccessCode() {
        coordinator?.openAccessCodeView(analyticsContextParams: getContextParams(), callback: saveAccessCode)
    }
}

extension NotificationCenter {
    static var didBecomeActivePublisher: AnyPublisher<Notification, Error> {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

private extension BackupService {
    var allCardIds: Set<String> {
        let ids = [primaryCard?.cardId].compactMap { $0 } + backupCards.map { $0.cardId }
        return Set(ids)
    }

    /// for ring onboarding
    var allBatchIds: [String] {
        [primaryCard?.batchId].compactMap { $0 } + backupCards.compactMap { $0.batchId }
    }

    var isFinalizingRing: Bool {
        if let finalizingBatchId,
           RingUtil().isRing(batchId: finalizingBatchId) {
            return true
        }

        return false
    }

    var isPrimaryRing: Bool {
        if let primaryCardBatchId = primaryCard?.batchId {
            return RingUtil().isRing(batchId: primaryCardBatchId)
        }

        return false
    }

    /// for ring onboarding
    private var finalizingBatchId: String? {
        if currentState == .finalizingPrimaryCard,
           let batchId = primaryCard?.batchId {
            return batchId
        }

        if case .finalizingBackupCard(let index) = currentState,
           let batchId = backupCards[index - 1].batchId {
            return batchId
        }

        return nil
    }
}
