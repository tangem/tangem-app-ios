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

    @Published private var isOffersUpdatesEnabled: Bool = false
    @Published private var isPriceAlertsEnabled: Bool = false
    @Published private var isSystemPermissionGranted: Bool = false

    private var isEnabledTransactionAlertsBinding: BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.transactionAlertsEnabled },
            set: { viewModel, value in
                viewModel.transactionAlertsEnabled = value
                viewModel.handleToggle(value: value, for: .transactionAlerts)
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
                viewModel.handleToggle(value: value, for: .offersUpdates)
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
                viewModel.handleToggle(value: value, for: .priceAlerts)
            }
        )
    }

    private var toggleTasks: [PushChannel: Task<Void, Never>] = [:]
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
        pushNotificationsPermission.isAuthorizedPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isAuthorized in
                viewModel.isSystemPermissionGranted = isAuthorized
                viewModel.allowNotificationsBannerInput = isAuthorized ? nil : viewModel.makeAllowNotificationsBannerInput()
            }
            .store(in: &bag)

        $isSystemPermissionGranted
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.rebuildToggleViewModels()
            }
            .store(in: &bag)

        userTokensPushNotificationsManager
            .preferencesPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, preferences in
                viewModel.applyPreferences(preferences)
            }
            .store(in: &bag)
    }

    func setupViewModels() {
        transactionAlertsEnabled = userTokensPushNotificationsManager.status.isActive
        rebuildToggleViewModels()
    }

    func rebuildToggleViewModels() {
        let isPermissionDenied = !isSystemPermissionGranted

        transactionAlertsViewModel = DefaultToggleRowViewModel(
            title: Localization.pushTransactionsNotificationsTitle,
            isDisabled: isPermissionDenied,
            isOn: isEnabledTransactionAlertsBinding
        )

        offersUpdatesViewModel = DefaultToggleRowViewModel(
            title: Localization.pushNotificationSettingsOffersUpdatesTitle,
            isDisabled: isPermissionDenied,
            isOn: isEnabledOffersUpdatesBinding
        )

        priceAlertsViewModel = DefaultToggleRowViewModel(
            title: Localization.pushNotificationSettingsPriceAlertsTitle,
            isDisabled: isPermissionDenied,
            isOn: isEnabledPriceAlertsEnabledBinding
        )
    }

    func applyPreferences(_ preferences: RemotePushPreferences) {
        transactionAlertsEnabled = preferences.preference(for: .transactionAlerts).isEnabled
        offersUpdatesEnabled = preferences.preference(for: .offersUpdates).isEnabled
        priceAlertsEnabled = preferences.preference(for: .priceAlerts).isEnabled
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
                // Do nothing.
            } else {
                // To display a system message about the need for permission to receive notifications.
                viewModel.displayEnablePushSettingsAlert()
            }

            viewModel.refreshBannerVisibility()
        }
    }
}

// MARK: - Channel Toggle Handling

private extension NotificationSettingsViewModel {
    /// Optimistically updates the UI (via the binding setter), then sends the request to the
    /// manager. On failure the `preferencesPublisher` subscription rolls back the toggle
    /// automatically and we surface a generic error alert.
    func handleToggle(value: Bool, for channel: PushChannel) {
        toggleTasks[channel]?.cancel()

        toggleTasks[channel] = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await userTokensPushNotificationsManager.tryUpdateEnableState(value: value, for: channel)
            } catch is CancellationError {
                return
            } catch {
                displayPreferenceUpdateFailedAlert()
            }
        }
    }
}

// MARK: - In-memory Toggles (Offers / Price Alerts)

private extension NotificationSettingsViewModel {
    /// Handles a toggle change for Offers & Updates or Price Alerts:
    /// - Disabling: sends PUT immediately (optimistic, reverts on error).
    /// - Enabling: requests system permission first, then sends PUT.
    func handlePreferenceToggle(newValue: Bool, setter: @escaping (Bool) -> Void) {
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
    func displayPreferenceUpdateFailedAlert() {
        alert = AlertBinder(title: "Something went wrong", message: "Please try again later.")
    }

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
