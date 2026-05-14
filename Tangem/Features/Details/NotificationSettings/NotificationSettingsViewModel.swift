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
    @Injected(\.userTokensPushNotificationsService) private var userTokensPushNotificationsService: UserTokensPushNotificationsService

    // MARK: - ViewState

    @Published private(set) var allowNotificationsBannerInput: NotificationViewInput?

    @Published var isPushNotifyEnabled: Bool = false
    @Published private(set) var pushNotifyViewModel: DefaultToggleRowViewModel?
    @Published private(set) var warningPermissionViewModel: DefaultWarningRowViewModel?

    var isTransactionPushVisible: Bool {
        pushNotifyViewModel != nil || warningPermissionViewModel != nil
    }

    @Published private(set) var offersUpdatesViewModel: DefaultToggleRowViewModel?
    @Published private(set) var priceAlertsViewModel: DefaultToggleRowViewModel?

    @Published var alert: AlertBinder?

    // MARK: - Private

    private let userWalletModel: UserWalletModel
    private weak var coordinator: NotificationSettingsRoutable?

    /// `nil` when the wallet is not eligible for transaction push notifications.
    private var userTokensPushNotificationsManager: UserTokensPushNotificationsManager?

    /// In-memory state for non-functional toggles (Offers & Updates, Price Alerts).
    @Published private var isOffersUpdatesEnabled: Bool = false
    @Published private var isPriceAlertsEnabled: Bool = false

    private var isEnabledPushNotificationStatusBinding: BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.isPushNotifyEnabled },
            set: { viewModel, value in
                viewModel.isPushNotifyEnabled = value
                viewModel.handleTogglePushNotifyStatus(toggleValue: value)
            }
        )
    }

    private var requestPermissionTask: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(userWalletModel: UserWalletModel, coordinator: NotificationSettingsRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator

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

        userTokensPushNotificationsManager?
            .statusPublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, status in
                viewModel.isPushNotifyEnabled = status.isActive
                viewModel.displayPermissionWarningIfNeeded(for: status)
            }
            .store(in: &bag)
    }

    func setupViewModels() {
        let isEligible = userTokensPushNotificationsService.entries.contains { $0.id == userWalletModel.userWalletId.stringValue }
        if isEligible {
            userTokensPushNotificationsManager = userWalletModel.userTokensPushNotificationsManager
            isPushNotifyEnabled = userWalletModel.userTokensPushNotificationsManager.status.isActive
        }

        if let manager = userTokensPushNotificationsManager {
            let currentStatus = manager.status

            // One-time initialization. Because isNotInitialized is non-recoverable
            pushNotifyViewModel = DefaultToggleRowViewModel(
                title: Localization.walletSettingsPushNotificationsTitle,
                isDisabled: currentStatus.isNotInitialized,
                isOn: isEnabledPushNotificationStatusBinding
            )

            displayPermissionWarningIfNeeded(for: currentStatus)
        }

        offersUpdatesViewModel = DefaultToggleRowViewModel(
            title: NotificationSettingsViewModel.Constants.offersUpdatesTitle,
            isOn: BindingValue<Bool>(
                root: self,
                default: false,
                get: { $0.isOffersUpdatesEnabled },
                set: { viewModel, newValue in
                    viewModel.handleInMemoryToggleWithPermission(
                        newValue: newValue,
                        setter: { viewModel.isOffersUpdatesEnabled = $0 }
                    )
                }
            )
        )

        priceAlertsViewModel = DefaultToggleRowViewModel(
            title: NotificationSettingsViewModel.Constants.priceAlertsTitle,
            isOn: BindingValue<Bool>(
                root: self,
                default: false,
                get: { $0.isPriceAlertsEnabled },
                set: { viewModel, newValue in
                    viewModel.handleInMemoryToggleWithPermission(
                        newValue: newValue,
                        setter: { viewModel.isPriceAlertsEnabled = $0 }
                    )
                }
            )
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
            self?.coordinator?.openAppSettings()
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
    func displayPermissionWarningIfNeeded(for status: UserWalletPushNotifyStatus) {
        if case .unavailable(let reason, let enabledRemote) = status, enabledRemote, reason == .permissionDenied {
            warningPermissionViewModel = DefaultWarningRowViewModel(
                title: Localization.transactionNotificationsWarningTitle,
                subtitle: Localization.transactionNotificationsWarningDescription,
                leftView: .icon(Assets.attention)
            )
        } else {
            warningPermissionViewModel = nil
        }
    }

    /// Handles the state changes of the transaction push notifications toggle.
    ///
    /// Mirrors the legacy `TransactionNotificationsRowToggleViewModel` behavior:
    /// - `.enabled` / `.disabled` → push status flip based on the new toggle value.
    /// - `.unavailable(.permissionDenied)` + enabling → request authorization (and show settings alert if denied).
    /// - `.unavailable(.permissionDenied)` + disabling → mark remote as disabled, keep blocked state.
    /// - Other states (e.g. `.notInitialized`) → no-op; toggle is rendered as disabled.
    func handleTogglePushNotifyStatus(toggleValue: Bool) {
        guard let manager = userTokensPushNotificationsManager else { return }

        Analytics.log(.pushToggleClicked, params: [.state: toggleValue ? .on : .off])

        let toUpdatePushNotifyStatus: UserWalletPushNotifyStatus

        switch manager.status {
        case .enabled, .disabled:
            toUpdatePushNotifyStatus = toggleValue ? .enabled : .disabled
        case .unavailable(let blockedReason, _) where blockedReason == .permissionDenied && toggleValue:
            handleAndCheckUnavailablePushNotifyStatus()
            return
        case .unavailable(let blockedReason, _) where blockedReason == .permissionDenied && !toggleValue:
            toUpdatePushNotifyStatus = .unavailable(reason: .permissionDenied, enabledRemote: false)
        default:
            // DefaultToggleRowViewModel did at disabled state. The status does not need to be updated
            return
        }

        manager.handleUpdateWalletPushNotifyStatus(toUpdatePushNotifyStatus)
    }

    func handleAndCheckUnavailablePushNotifyStatus() {
        requestPermissionTask?.cancel()

        requestPermissionTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.pushNotificationsPermission.requestAuthorizationAndRegister()

            if await viewModel.pushNotificationsPermission.isAuthorized {
                viewModel.userTokensPushNotificationsManager?.handleUpdateWalletPushNotifyStatus(.enabled)
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
                    self?.isPushNotifyEnabled = false
                    self?.coordinator?.onAlertDismiss()
                }
            ),
            secondaryButton: .default(
                Text(Localization.pushNotificationsPermissionAlertPositiveButton),
                action: { [weak self] in
                    self?.isPushNotifyEnabled = false
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

// MARK: - Constants

extension NotificationSettingsViewModel {
    enum Constants {
        static let screenTitle = "Notification Settings"

        static let offersUpdatesTitle = "Offers & Updates"
        static let offersUpdatesFooter = "Product news, exclusive offers, and activity reminders."

        static let priceAlertsTitle = "Price Alerts"
        static let priceAlertsFooter = "Get notified about price changes for top market coins."
    }
}
