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
    @Injected(\.pushNotificationsSyncService) private var pushNotificationsSyncService: PushNotificationsSyncService

    // MARK: - ViewState

    @Published private(set) var allowNotificationsBannerInput: NotificationViewInput?
    @Published private(set) var transactionNotificationsRowToggleViewModel: TransactionNotificationsRowToggleViewModel?

    @Published private(set) var offersUpdatesViewModel: DefaultToggleRowViewModel?
    @Published private(set) var priceAlertsViewModel: DefaultToggleRowViewModel?

    @Published var alert: AlertBinder?

    // MARK: - Private

    private let userWalletModel: UserWalletModel
    private weak var coordinator: NotificationSettingsRoutable?

    /// `nil` when the wallet is not eligible for transaction push notifications.
    private var userTokensPushNotificationsManager: UserTokensPushNotificationsManager?

    @Published private var isOffersUpdatesEnabled: Bool = false
    @Published private var isPriceAlertsEnabled: Bool = false

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
    }

    func setupViewModels() {
        userTokensPushNotificationsManager = userWalletModel.userTokensPushNotificationsManager

        if let manager = userTokensPushNotificationsManager {
            transactionNotificationsRowToggleViewModel = TransactionNotificationsRowToggleViewModel(
                userTokensPushNotificationsManager: manager,
                coordinator: coordinator,
                showPushSettingsAlert: weakify(self, forFunction: NotificationSettingsViewModel.displayEnablePushSettingsAlert)
            )
        }

        offersUpdatesViewModel = DefaultToggleRowViewModel(
            title: NotificationSettingsViewModel.Constants.offersUpdatesTitle,
            isOn: BindingValue<Bool>(
                root: self,
                default: false,
                get: { $0.isOffersUpdatesEnabled },
                set: { viewModel, newValue in
                    viewModel.handlePreferenceToggle(
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
                    viewModel.handlePreferenceToggle(
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

// MARK: - Remote Toggles (Offers / Price Alerts)

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
    func displayEnablePushSettingsAlert() {
        let buttons: AlertBuilder.Buttons = .init(
            primaryButton: .default(
                Text(Localization.pushNotificationsPermissionAlertNegativeButton),
                action: { [weak self] in
                    self?.transactionNotificationsRowToggleViewModel?.isPushNotifyEnabled = false
                    self?.coordinator?.onAlertDismiss()
                }
            ),
            secondaryButton: .default(
                Text(Localization.pushNotificationsPermissionAlertPositiveButton),
                action: { [weak self] in
                    self?.transactionNotificationsRowToggleViewModel?.isPushNotifyEnabled = false
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
