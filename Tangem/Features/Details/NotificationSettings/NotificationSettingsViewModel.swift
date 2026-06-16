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
    func bind() {
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
            await viewModel.pushNotificationsPermission.requestAuthorizationAndRegister()

            if await !viewModel.pushNotificationsPermission.isAuthorized {
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
