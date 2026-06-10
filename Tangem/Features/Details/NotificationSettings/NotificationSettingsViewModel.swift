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

    private var userTokensPushNotificationsManager: UserTokensPushNotificationsManager

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
    private var pendingEnableChannel: PushChannel?
    private var bannerActionTask: Task<Void, Never>?
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
        refreshSystemPermissionState()
    }

    func onTapMoreInfoTransactionPushNotifications() {
        coordinator?.openTransactionNotifications()
    }
}

// MARK: - Private

private extension NotificationSettingsViewModel {
    enum PendingEnableAuthorizationUpdateSource {
        case isAuthorizedPublisher
        case authorizationRequestFallback
    }

    func bind() {
        // `isAuthorizedPublisher` only emits on `UIApplication.didBecomeActive`, so this branch
        // covers the case when the user returns from system Settings. The initial state on screen
        // open is primed by `refreshSystemPermissionState()` from `onAppear()`.
        pushNotificationsPermission.isAuthorizedPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isAuthorized in
                viewModel.isSystemPermissionGranted = isAuthorized
                viewModel.handlePendingEnableAuthorizationUpdate(
                    isAuthorized: isAuthorized,
                    source: .isAuthorizedPublisher
                )
            }
            .store(in: &bag)

        // Single source of truth: any change to the system permission flag drives both the toggle
        // disabled state and the "Allow notifications" banner visibility.
        $isSystemPermissionGranted
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isAuthorized in
                viewModel.rebuildToggleViewModels()
                viewModel.allowNotificationsBannerInput = isAuthorized ? nil : viewModel.makeAllowNotificationsBannerInput()
            }
            .store(in: &bag)

        userTokensPushNotificationsManager
            .preferencesPublisher
            .removeDuplicates()
            .receiveOnMain()
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
        transactionAlertsViewModel = DefaultToggleRowViewModel(
            title: Localization.pushTransactionsNotificationsTitle,
            isOn: isEnabledTransactionAlertsBinding
        )

        offersUpdatesViewModel = DefaultToggleRowViewModel(
            title: Localization.pushNotificationSettingsOffersUpdatesTitle,
            isOn: isEnabledOffersUpdatesBinding
        )

        priceAlertsViewModel = DefaultToggleRowViewModel(
            title: Localization.pushNotificationSettingsPriceAlertsTitle,
            isOn: isEnabledPriceAlertsEnabledBinding
        )
    }

    func applyPreferences(_ preferences: RemotePushPreferences) {
        transactionAlertsEnabled = preferences.preference(for: .transactionAlerts).isEnabled
        offersUpdatesEnabled = preferences.preference(for: .offersUpdates).isEnabled
        priceAlertsEnabled = preferences.preference(for: .priceAlerts).isEnabled
    }

    /// Pulls the current system authorization status and writes it into `isSystemPermissionGranted`,
    /// which in turn drives `rebuildToggleViewModels()` and `allowNotificationsBannerInput` through
    /// the `$isSystemPermissionGranted` subscription in `bind()`.
    func refreshSystemPermissionState() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            isSystemPermissionGranted = await pushNotificationsPermission.isAuthorized
        }
    }

    func makeAllowNotificationsBannerInput() -> NotificationViewInput {
        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] _, _ in
            self?.handleBannerOpenSettingsTap()
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

// MARK: - Channel Toggle Handling

private extension NotificationSettingsViewModel {
    /// Optimistically updates the UI (via the binding setter), then sends the request to the
    /// manager. On failure the `preferencesPublisher` subscription rolls back the toggle
    /// automatically and we surface a generic error alert.
    ///
    /// When trying to enable while system permission is not granted, we switch into a pending
    /// state and request iOS authorization. The final decision is primarily processed from
    /// `isAuthorizedPublisher`; if iOS doesn't surface a system prompt anymore (already denied),
    /// we fall back to showing our own settings alert.
    func handleToggle(value: Bool, for channel: PushChannel) {
        toggleTasks[channel]?.cancel()

        toggleTasks[channel] = Task { @MainActor [weak self] in
            guard let self else { return }

            if value, !isSystemPermissionGranted {
                pendingEnableChannel = channel

                // The awaits below aren't cooperatively cancellable, so guard explicitly after each:
                // a superseding toggle cancels this task but can't stop these calls from resuming,
                // and the resumed continuation would otherwise mutate pending state out of order.
                await pushNotificationsPermission.requestAuthorizationAndRegister()
                guard !Task.isCancelled else { return }

                // If iOS prompt wasn't shown, `isAuthorizedPublisher` may not emit.
                // Resolve pending state from a direct snapshot in this fallback path.
                let isAuthorized = await pushNotificationsPermission.isAuthorized
                guard !Task.isCancelled else { return }

                handlePendingEnableAuthorizationUpdate(
                    isAuthorized: isAuthorized,
                    source: .authorizationRequestFallback
                )
                return
            }

            if !value, pendingEnableChannel == channel {
                pendingEnableChannel = nil
            }

            // Don't start a backend write for a task that was already superseded by a newer toggle.
            guard !Task.isCancelled else { return }

            do {
                try await userTokensPushNotificationsManager.tryUpdateEnableState(value: value, for: channel)
            } catch is CancellationError {
                return
            } catch {
                displayPreferenceUpdateFailedAlert()
            }
        }
    }

    func handlePendingEnableAuthorizationUpdate(
        isAuthorized: Bool,
        source: PendingEnableAuthorizationUpdateSource
    ) {
        guard let channel = pendingEnableChannel else {
            return
        }

        if isAuthorized {
            pendingEnableChannel = nil
            tryEnablePendingChannel(channel)
            return
        }

        switch source {
        case .isAuthorizedPublisher:
            pendingEnableChannel = nil
            revertToggle(for: channel)
        case .authorizationRequestFallback:
            displayEnablePushSettingsAlert(for: channel)
        }
    }

    func tryEnablePendingChannel(_ channel: PushChannel) {
        toggleTasks[channel]?.cancel()
        toggleTasks[channel] = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await userTokensPushNotificationsManager.tryUpdateEnableState(value: true, for: channel)
            } catch is CancellationError {
                return
            } catch {
                displayPreferenceUpdateFailedAlert()
            }
        }
    }

    func revertToggle(for channel: PushChannel) {
        switch channel {
        case .transactionAlerts: transactionAlertsEnabled = false
        case .offersUpdates: offersUpdatesEnabled = false
        case .priceAlerts: priceAlertsEnabled = false
        }
    }
}

// MARK: - Banner Action

private extension NotificationSettingsViewModel {
    /// Handles the «Open Settings» tap on the allow-notifications banner:
    /// 1. Requests system authorization (shows the iOS prompt if not yet decided).
    /// 2. If authorization is still denied after the prompt, opens the app's system Settings page.
    /// 3. No toggles are flipped — the `$isSystemPermissionGranted` pipeline reacts automatically
    ///    when the user returns from Settings via `isAuthorizedPublisher`.
    func handleBannerOpenSettingsTap() {
        bannerActionTask?.cancel()

        bannerActionTask = runTask(in: self) { @MainActor viewModel in
            // The awaits below aren't cooperatively cancellable; guard explicitly so a superseding
            // tap doesn't let a resumed continuation open Settings or refresh state out of order.
            await viewModel.pushNotificationsPermission.requestAuthorizationAndRegister()
            guard !Task.isCancelled else { return }

            let isAuthorized = await viewModel.pushNotificationsPermission.isAuthorized
            guard !Task.isCancelled else { return }

            if !isAuthorized {
                viewModel.coordinator?.openAppSettings()
            }

            viewModel.refreshSystemPermissionState()
        }
    }
}

// MARK: - Alerts

private extension NotificationSettingsViewModel {
    func displayPreferenceUpdateFailedAlert() {
        alert = AlertBinder(
            title: Localization.commonError,
            message: Localization.commonSomethingWentWrong
        )
    }

    func displayEnablePushSettingsAlert(for channel: PushChannel) {
        let buttons: AlertBuilder.Buttons = .init(
            primaryButton: .default(
                Text(Localization.pushNotificationsPermissionAlertNegativeButton),
                action: { [weak self] in
                    self?.pendingEnableChannel = nil
                    self?.revertToggle(for: channel)
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
