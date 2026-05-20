//
//  NotificationSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemAssets
import struct TangemUIUtils.AlertBinder

final class NotificationSettingsViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.pushNotificationsPermission) private var pushNotificationsPermission: PushNotificationsPermissionService

    // MARK: - ViewState

    @Published private(set) var allowNotificationsBannerInput: NotificationViewInput?

    @Published var transactionAlertsEnabled: Bool = false
    @Published var offersUpdatesEnabled: Bool = false
    @Published var priceAlertsEnabled: Bool = false

    @Published private(set) var transactionAlertsViewModel: DefaultToggleRowViewModel?
    @Published private(set) var offersUpdatesViewModel: DefaultToggleRowViewModel?
    @Published private(set) var priceAlertsViewModel: DefaultToggleRowViewModel?

    @Published var alert: AlertBinder?

    // MARK: - Private

    private let userWalletModel: UserWalletModel
    private weak var coordinator: NotificationSettingsRoutable?

    /// `nil` when the wallet is not eligible for transaction push notifications.
    private var userTokensPushNotificationsManager: UserTokensPushNotificationsManager

    /// In-memory state for non-functional toggles (Offers & Updates, Price Alerts).
    @Published private var isOffersUpdatesEnabled: Bool = false
    @Published private var isPriceAlertsEnabled: Bool = false

    private var isEnabledTransactionAlertsBinding: BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.transactionAlertsEnabled },
            set: { viewModel, value in
                viewModel.transactionAlertsEnabled = value
                // [REDACTED_TODO_COMMENT]
            }
        )
    }

    private var isEnabledOffersUpdatesBinding: BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.offersUpdatesEnabled },
            set: { viewModel, value in
                viewModel.offersUpdatesEnabled = value
                // [REDACTED_TODO_COMMENT]
            }
        )
    }

    private var isEnabledPriceAlertsEnabledBinding: BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.priceAlertsEnabled },
            set: { viewModel, value in
                viewModel.priceAlertsEnabled = value
                // [REDACTED_TODO_COMMENT]
            }
        )
    }

    private var requestPermissionTask: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(userWalletModel: UserWalletModel, coordinator: NotificationSettingsRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator

        userTokensPushNotificationsManager = userWalletModel.userTokensPushNotificationsManager

        setupViewModels()
        bind()
    }

    // MARK: - Lifecycle

    func onAppear() {
        refreshBannerVisibility()
    }

    func onTapMoreInfoTransactionPushNotifications() {
        coordinator?.openTransactionNotifications()
    }
}

// MARK: - Private

private extension NotificationSettingsViewModel {
    func bind() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.refreshBannerVisibility()
            }
            .store(in: &bag)

        // [REDACTED_TODO_COMMENT]
        userTokensPushNotificationsManager
            .statusPublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, status in }
            .store(in: &bag)
    }

    func setupViewModels() {
        let userTokensPushNotificationsManager = userWalletModel.userTokensPushNotificationsManager

        transactionAlertsEnabled = userTokensPushNotificationsManager.status.isActive

        // One-time initialization. Because isNotInitialized is non-recoverable
        transactionAlertsViewModel = DefaultToggleRowViewModel(
            title: Localization.pushTransactionsNotificationsTitle,
            isDisabled: userTokensPushNotificationsManager.status.isNotInitialized,
            isOn: isEnabledTransactionAlertsBinding
        )

        offersUpdatesViewModel = DefaultToggleRowViewModel(
            title: Localization.pushNotificationSettingsOffersUpdatesTitle,
            isOn: isEnabledOffersUpdatesBinding
        )

        priceAlertsViewModel = DefaultToggleRowViewModel(
            title: Localization.pushNotificationSettingsPriceAlertsTitle,
            isDisabled: userTokensPushNotificationsManager.status.isNotInitialized,
            isOn: isEnabledPriceAlertsEnabledBinding
        )
    }

    func refreshBannerVisibility() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let isAuthorized = await pushNotificationsPermission.isAuthorized
            allowNotificationsBannerInput = isAuthorized ? nil : makeAllowNotificationsBannerInput()
        }
    }

    func makeAllowNotificationsBannerInput() -> NotificationViewInput {
        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] _, _ in
            self?.handleAndCheckUnavailablePushNotifyStatus()
        }

        return NotificationViewInput(
            style: .withButtons([
                NotificationView.NotificationButton(
                    action: buttonAction,
                    actionType: .openPushNotificationsSystemSettings,
                    isWithLoader: false
                ),
            ]),
            severity: .warning,
            settings: .init(event: PushSettingsNotificationsEvent.allowNotifications, dismissAction: nil)
        )
    }
}

// MARK: - Transaction Push Notifications

private extension NotificationSettingsViewModel {
    func handleAndCheckUnavailablePushNotifyStatus() {
        requestPermissionTask?.cancel()

        requestPermissionTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.pushNotificationsPermission.requestAuthorizationAndRegister()

            if await viewModel.pushNotificationsPermission.isAuthorized {
                // [REDACTED_TODO_COMMENT]
            } else {
                // To display a system message about the need for permission to receive notifications.
                viewModel.displayEnablePushSettingsAlert()
            }

            viewModel.refreshBannerVisibility()
        }
    }
}

// MARK: - In-memory Toggles (Offers / Price Alerts)

private extension NotificationSettingsViewModel {
    /// For non-functional toggles (Offers & Updates, Price Alerts):
    /// - Enabling triggers system permission request flow (matches existing transaction toggle behavior).
    /// - State is kept in memory only; no backend or persistence side effects.
    func handleInMemoryToggleWithPermission(newValue: Bool, setter: @escaping (Bool) -> Void) {
        if !newValue {
            setter(false)
            return
        }

        requestPermissionTask?.cancel()
        requestPermissionTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.pushNotificationsPermission.requestAuthorizationAndRegister()

            if await viewModel.pushNotificationsPermission.isAuthorized {
                setter(true)
            } else {
                setter(false)
                viewModel.displayEnablePushSettingsAlert()
            }

            viewModel.refreshBannerVisibility()
        }
    }
}

// MARK: - Alerts

private extension NotificationSettingsViewModel {
    func displayEnablePushSettingsAlert() {
        let buttons: AlertBuilder.Buttons = .init(
            primaryButton: .default(
                Text(Localization.pushNotificationsPermissionAlertNegativeButton),
                action: { [weak self] in
                    self?.coordinator?.onAlertDismiss()
                }
            ),
            secondaryButton: .default(
                Text(Localization.pushNotificationsPermissionAlertPositiveButton),
                action: { [weak self] in
                    self?.coordinator?.openAppSettings()
                    self?.coordinator?.onAlertDismiss()
                }
            )
        )

        alert = AlertBuilder.makeAlert(
            title: Localization.pushNotificationsPermissionAlertTitle,
            message: Localization.pushNotificationsPermissionAlertDescription,
            with: buttons
        )
    }
}
