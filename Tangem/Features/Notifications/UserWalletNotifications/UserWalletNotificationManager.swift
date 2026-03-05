//
//  UserWalletNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

protocol NotificationTapDelegate: AnyObject {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType)
}

/// Manager for handling Notifications related to UserWalletModel.
/// Don't forget to setup manager with delegate for proper notification handling
final class UserWalletNotificationManager {
    @Injected(\.deprecationService) private var deprecationService: DeprecationServicing
    @Injected(\.userWalletDismissedNotifications) private var dismissedNotifications: UserWalletDismissedNotifications

    private let analyticsService: NotificationsAnalyticsService
    private let userWalletModel: UserWalletModel
    private let rateAppController: RateAppNotificationController
    private let mobileUpgradeBannerManager: MobileUpgradeBannerManager
    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private weak var delegate: NotificationTapDelegate?
    private var bag = Set<AnyCancellable>()

    private var numberOfPendingDerivations: Int = 0

    private var showAppRateNotification = false
    private var shownAppRateNotificationId: NotificationViewId?

    private var shownMobileActivationNotificationId: NotificationViewId?

    private var showMobileUpgradeNotification = false
    private var shownMobileUpgradeNotificationId: NotificationViewId?

    private lazy var supportSeedNotificationInteractor: SupportSeedNotificationManager = makeSupportSeedNotificationsManager()
    private lazy var pushPermissionNotificationInteractor: PushPermissionNotificationManager = makePushPermissionNotificationsManager()

    init(
        userWalletModel: UserWalletModel,
        rateAppController: RateAppNotificationController
    ) {
        self.userWalletModel = userWalletModel
        self.rateAppController = rateAppController
        analyticsService = NotificationsAnalyticsService(userWalletId: userWalletModel.userWalletId)
        mobileUpgradeBannerManager = CommonMobileUpgradeBannerManager(userWalletModel: userWalletModel)

        bind()
    }

    private func createNotifications() {
        let factory = NotificationsFactory()
        let action: NotificationView.NotificationAction = { [weak self] id in
            self?.delegate?.didTapNotification(with: id, action: .empty)
        }

        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            self?.delegate?.didTapNotification(with: id, action: action)
        }

        let dismissAction: NotificationView.NotificationAction = weakify(self, forFunction: UserWalletNotificationManager.dismissNotification)

        var inputs: [NotificationViewInput] = []

        if !userWalletModel.validate() {
            inputs.append(
                factory.buildNotificationInput(
                    for: .backupErrors,
                    action: action,
                    buttonAction: buttonAction,
                    dismissAction: dismissAction
                )
            )
        }

        inputs.append(contentsOf: factory.buildNotificationInputs(
            for: deprecationService.deprecationWarnings,
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        ))

        // We need to remove legacyDerivation WarningEvent, because it must be shown in Manage tokens only
        let eventsWithoutDerivationWarning = userWalletModel.config.generalNotificationEvents.filter { $0 != .legacyDerivation }
        inputs.append(contentsOf: factory.buildNotificationInputs(
            for: eventsWithoutDerivationWarning,
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        ))

        if numberOfPendingDerivations > 0 {
            inputs.append(
                factory.buildNotificationInput(
                    for: .missingDerivation(
                        numberOfNetworks: numberOfPendingDerivations,
                        icon: CommonTangemIconProvider(config: userWalletModel.config).getMainButtonIcon()
                    ),
                    action: action,
                    buttonAction: buttonAction,
                    dismissAction: dismissAction
                )
            )
        }

        if userWalletModel.config.hasFeature(.backup) {
            inputs.append(
                factory.buildNotificationInput(
                    for: .missingBackup,
                    action: action,
                    buttonAction: buttonAction,
                    dismissAction: dismissAction
                )
            )
        }

        notificationInputsSubject.send(inputs)

        showAppRateNotificationIfNeeded()
        createIfNeededAndShowSupportSeedNotification()
        showMobileUpgradeNotificationIfNeeded()
        showMobileActivationNotificationIfNeeded()
        createAndShowPushPermissionNotificationIfNeeded()
    }

    private func createIfNeededAndShowSupportSeedNotification() {
        guard userWalletModel.hasImportedWallets else {
            return
        }

        // demo cards
        if case .disabled = userWalletModel.config.getFeatureAvailability(.backup) {
            return
        }

        supportSeedNotificationInteractor.showSupportSeedNotificationIfNeeded()
    }

    private func createAndShowPushPermissionNotificationIfNeeded() {
        pushPermissionNotificationInteractor.showPushPermissionNotificationIfNeeded()
    }

    private func hideNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }

    private func showAppRateNotificationIfNeeded() {
        guard showAppRateNotification else {
            hideShownAppRateNotificationIfNeeded()
            return
        }

        let factory = NotificationsFactory()

        let action: NotificationView.NotificationAction = { [weak self] id in
            self?.delegate?.didTapNotification(with: id, action: .empty)
        }

        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            self?.delegate?.didTapNotification(with: id, action: action)
        }

        let dismissAction: NotificationView.NotificationAction = weakify(self, forFunction: UserWalletNotificationManager.dismissNotification)

        let input = factory.buildNotificationInput(
            for: .rateApp,
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        )
        shownAppRateNotificationId = input.id

        addInputIfNeeded(input)
    }

    private func hideShownAppRateNotificationIfNeeded() {
        guard let shownAppRateNotificationId else {
            return
        }

        hideNotification(with: shownAppRateNotificationId)
        self.shownAppRateNotificationId = nil
    }

    private func addInputIfNeeded(_ input: NotificationViewInput) {
        guard !notificationInputsSubject.value.contains(where: { $0.id == input.id }) else {
            return
        }

        notificationInputsSubject.value.insert(input, at: 0)
    }

    private func showMobileActivationNotificationIfNeeded() {
        hideMobileActivationNotificationIfNeeded()

        let config = userWalletModel.config
        let needBackup = config.hasFeature(.mnemonicBackup) && config.hasFeature(.iCloudBackup)
        let needAccessCode = config.hasFeature(.userWalletAccessCode) && config.userWalletAccessCodeStatus == .none

        guard needBackup || needAccessCode else {
            return
        }

        let factory = NotificationsFactory()

        let action: NotificationView.NotificationAction = { _ in }

        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            self?.delegate?.didTapNotification(with: id, action: action)
        }

        let dismissAction: NotificationView.NotificationAction = weakify(self, forFunction: UserWalletNotificationManager.dismissNotification)

        let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)
        let totalBalances = walletModels.compactMap(\.availableBalanceProvider.balanceType.value)
        let hasPositiveBalance = totalBalances.contains(where: { $0 > 0 })

        let input = factory.buildNotificationInput(
            for: .mobileFinishActivation(hasPositiveBalance: hasPositiveBalance, hasBackup: !needBackup),
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        )

        shownMobileActivationNotificationId = input.id
        addInputIfNeeded(input)
    }

    private func hideMobileActivationNotificationIfNeeded() {
        guard let shownMobileActivationNotificationId else {
            return
        }

        hideNotification(with: shownMobileActivationNotificationId)
        self.shownMobileActivationNotificationId = nil
    }

    private func showMobileUpgradeNotificationIfNeeded() {
        guard showMobileUpgradeNotification else {
            hideMobileUpgradeNotificationIfNeeded()
            return
        }

        let factory = NotificationsFactory()

        let action: NotificationView.NotificationAction = { _ in }

        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            if case .closeMobileUpgrade = action {
                self?.dismissNotification(with: id)
            } else {
                self?.delegate?.didTapNotification(with: id, action: action)
            }
        }

        let dismissAction: NotificationView.NotificationAction = { _ in }

        let input = factory.buildNotificationInput(
            for: .mobileUpgrade,
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        )
        shownMobileUpgradeNotificationId = input.id

        addInputIfNeeded(input)
    }

    private func hideMobileUpgradeNotificationIfNeeded() {
        guard let shownMobileUpgradeNotificationId else {
            return
        }

        hideNotification(with: shownMobileUpgradeNotificationId)
        self.shownMobileUpgradeNotificationId = nil
    }

    private func bind() {
        notificationPublisher
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, notifications in
                manager.analyticsService.sendEventsIfNeeded(for: notifications)
            })
            .store(in: &bag)

        userWalletModel.updatePublisher
            .filter { value in
                switch value {
                case .configurationChanged:
                    return true
                case .nameDidChange:
                    return false
                }
            }
            .mapToVoid()
            .sink(receiveValue: weakify(self, forFunction: UserWalletNotificationManager.createNotifications))
            .store(in: &bag)

        makePendingDerivationsCountPublisher()?
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: weakify(self, forFunction: UserWalletNotificationManager.addMissingDerivationWarningIfNeeded(pendingDerivationsCount:)))
            .store(in: &bag)

        rateAppController
            .showAppRateNotificationPublisher
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, shouldShow in
                manager.showAppRateNotification = shouldShow
                manager.showAppRateNotificationIfNeeded()
            })
            .store(in: &bag)

        userWalletModel
            .totalBalancePublisher
            .map { $0.hasAnyPositiveBalance }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, shouldShow in
                manager.showMobileActivationNotificationIfNeeded()
            })
            .store(in: &bag)

        mobileUpgradeBannerManager
            .shouldShowPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { manager, shouldShow in
                manager.showMobileUpgradeNotification = shouldShow
                manager.showMobileUpgradeNotificationIfNeeded()
            }
            .store(in: &bag)
    }

    private func addMissingDerivationWarningIfNeeded(pendingDerivationsCount: Int) {
        guard numberOfPendingDerivations != pendingDerivationsCount else {
            return
        }

        numberOfPendingDerivations = pendingDerivationsCount
        createNotifications()
    }

    private func recordUserWalletHashesCountValidation() {
        AppSettings.shared.validatedSignedHashesCards.append(userWalletModel.userWalletId.stringValue)
    }

    private func recordDeprecationNotificationDismissal() {
        deprecationService.didDismissSystemDeprecationWarning()
    }

    private func makePendingDerivationsCountPublisher() -> AnyPublisher<Int, Never>? {
        guard FeatureProvider.isAvailable(.accounts) else {
            // accounts_fixes_needed_none
            return userWalletModel
                .userTokensManager
                .derivationManager?
                .pendingDerivationsCount
        }

        return userWalletModel
            .accountModelsManager
            .cryptoAccountModelsPublisher
            .map { $0.compactMap(\.userTokensManager.derivationManager) }
            .flatMapLatest { derivationManagers in
                return derivationManagers
                    .compactMap(\.pendingDerivationsCount)
                    .combineLatest()
                    .map { $0.reduce(0, +) }
            }
            .eraseToAnyPublisher()
    }

    private func makeSupportSeedNotificationsManager() -> SupportSeedNotificationManager {
        CommonSupportSeedNotificationManager(
            userWalletId: userWalletModel.userWalletId,
            displayDelegate: self,
            notificationTapDelegate: delegate
        )
    }

    private func makePushPermissionNotificationsManager() -> PushPermissionNotificationManager {
        CommonPushPermissionNotificationManager(displayDelegate: self, notificationTapDelegate: delegate)
    }
}

extension UserWalletNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate

        createNotifications()
    }

    func dismissNotification(with id: NotificationViewId) {
        guard let notification = notificationInputsSubject.value.first(where: { $0.id == id }) else {
            return
        }

        if let event = notification.settings.event as? GeneralNotificationEvent {
            switch event {
            case .systemDeprecationTemporary, .systemDeprecationPermanent:
                recordDeprecationNotificationDismissal()
            case .numberOfSignedHashesIncorrect:
                recordUserWalletHashesCountValidation()
            case .rateApp:
                rateAppController.dismissAppRate()
            case .mobileUpgrade:
                mobileUpgradeBannerManager.shouldClose()
            default:
                break
            }
        }

        hideNotification(with: id)
    }
}

// MARK: - SupportSeedNotificationDelegate

extension UserWalletNotificationManager: SupportSeedNotificationDelegate {
    func showSupportSeedNotification(input: NotificationViewInput) {
        addInputIfNeeded(input)
    }
}

// MARK: - PushPermissionNotificationDelegate

extension UserWalletNotificationManager: PushPermissionNotificationDelegate {
    func showPushPermissionNotification(input: NotificationViewInput) {
        addInputIfNeeded(input)
    }

    func hidePushPermissionNotification(with id: NotificationViewId) {
        hideNotification(with: id)
    }
}
