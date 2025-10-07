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
    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private weak var delegate: NotificationTapDelegate?
    private var bag = Set<AnyCancellable>()

    private var showReferralNotification = false

    private let referralNotificationController: ReferralNotificationController

    private var numberOfPendingDerivations: Int = 0

    private var showAppRateNotification = false
    private var shownAppRateNotificationId: NotificationViewId?

    private lazy var supportSeedNotificationInteractor: SupportSeedNotificationManager = makeSupportSeedNotificationsManager()
    private lazy var pushPermissionNotificationInteractor: PushPermissionNotificationManager = makePushPermissionNotificationsManager()

    init(
        userWalletModel: UserWalletModel,
        rateAppController: RateAppNotificationController,
        referralNotificationController: ReferralNotificationController
    ) {
        self.userWalletModel = userWalletModel
        self.rateAppController = rateAppController
        self.referralNotificationController = referralNotificationController
        analyticsService = NotificationsAnalyticsService(userWalletId: userWalletModel.userWalletId)

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
                    for: .missingDerivation(numberOfNetworks: numberOfPendingDerivations),
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

        if showReferralNotification == true {
            inputs.append(
                factory.buildNotificationInput(
                    for: .referralProgram,
                    action: action,
                    buttonAction: buttonAction,
                    dismissAction: dismissAction
                )
            )
        }

        notificationInputsSubject.send(inputs)

        showAppRateNotificationIfNeeded()
        createIfNeededAndShowSupportSeedNotification()
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
        guard FeatureProvider.isAvailable(.pushPermissionNotificationBanner) else {
            return
        }

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
        let config = userWalletModel.config
        let needBackup = config.hasFeature(.mnemonicBackup) && config.hasFeature(.iCloudBackup)
        let needAccessCode = config.hasFeature(.userWalletAccessCode) && !MobileAccessCodeSkipHelper.has(userWalletId: userWalletModel.userWalletId)

        guard needBackup || needAccessCode else {
            return
        }

        let factory = NotificationsFactory()

        let action: NotificationView.NotificationAction = { _ in }

        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            self?.delegate?.didTapNotification(with: id, action: action)
        }

        let dismissAction: NotificationView.NotificationAction = weakify(self, forFunction: UserWalletNotificationManager.dismissNotification)

        let hasPositiveBalance = userWalletModel.totalBalance.hasPositiveBalance

        Analytics.log(
            .noticeFinishActivation,
            params: [.balanceState: hasPositiveBalance ? .full : .empty]
        )

        let input = factory.buildNotificationInput(
            for: .mobileFinishActivation(needsAttention: hasPositiveBalance, hasBackup: !needBackup),
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        )

        addInputIfNeeded(input)
    }

    // [REDACTED_TODO_COMMENT]
    private func showMobileUpgradeNotificationIfNeeded() {
        let isDismissed = dismissedNotifications.has(userWalletId: userWalletModel.userWalletId, notification: .mobileUpgradeFromMain)

        guard userWalletModel.config.hasFeature(.userWalletUpgrade), !isDismissed else {
            return
        }

        let factory = NotificationsFactory()

        let action: NotificationView.NotificationAction = { [weak self] id in
            self?.delegate?.didTapNotification(with: id, action: .openMobileUpgrade)
        }

        let buttonAction: NotificationView.NotificationButtonTapAction = { _, _ in }

        let dismissAction: NotificationView.NotificationAction = weakify(self, forFunction: UserWalletNotificationManager.dismissNotification)

        let input = factory.buildNotificationInput(
            for: GeneralNotificationEvent.mobileUpgrade,
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        )

        addInputIfNeeded(input)
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
                case .nameDidChange, .tangemPayAccountCreated:
                    return false
                }
            }
            .mapToVoid()
            .sink(receiveValue: weakify(self, forFunction: UserWalletNotificationManager.createNotifications))
            .store(in: &bag)

        userWalletModel.userTokensManager.derivationManager?
            .pendingDerivationsCount
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

        referralNotificationController
            .showReferralNotificationPublisher
            .sink(receiveValue: { [weak self] value in
                guard let self else { return }

                showReferralNotification = value
                createNotifications()
            })
            .store(in: &bag)

        userWalletModel
            .totalBalancePublisher
            .map(\.hasPositiveBalance)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, _ in
                manager.createNotifications()
            })
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
        referralNotificationController.checkReferralStatus()
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
            case .referralProgram:
                referralNotificationController.dismissReferralNotification()
            case .mobileUpgrade:
                dismissedNotifications.add(userWalletId: userWalletModel.userWalletId, notification: .mobileUpgradeFromMain)
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
}
