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
    @Injected(\.userTokensPushNotificationsService) private var userTokensPushNotificationsService: UserTokensPushNotificationsService

    // MARK: - ViewState

    @Published private(set) var isBannerVisible: Bool = false
    @Published private(set) var transactionPushViewModel: TransactionNotificationsRowToggleViewModel?
    @Published private(set) var offersUpdatesViewModel: DefaultToggleRowViewModel?
    @Published private(set) var priceAlertsViewModel: DefaultToggleRowViewModel?

    @Published var alert: AlertBinder?

    // MARK: - Private

    private let userWalletModel: UserWalletModel
    private weak var coordinator: NotificationSettingsRoutable?

    /// In-memory state for non-functional toggles (see plan).
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

    func openAppSettingsFromBanner() {
        coordinator?.openAppSettings()
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
        if userTokensPushNotificationsService.entries.contains(where: { $0.id == userWalletModel.userWalletId.stringValue }) {
            transactionPushViewModel = TransactionNotificationsRowToggleViewModel(
                userTokensPushNotificationsManager: userWalletModel.userTokensPushNotificationsManager,
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
                    viewModel.handleToggleWithPermission(
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
                    viewModel.handleToggleWithPermission(
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
            isBannerVisible = !isAuthorized
        }
    }

    /// For non-functional toggles (Offers & Updates, Price Alerts):
    /// - Enabling triggers system permission request flow (matches existing transaction toggle behavior).
    /// - State is kept in memory only; no backend or persistence side effects.
    func handleToggleWithPermission(newValue: Bool, setter: @escaping (Bool) -> Void) {
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

// MARK: - Constants

extension NotificationSettingsViewModel {
    enum Constants {
        static let screenTitle = "Notification Settings"

        static let offersUpdatesTitle = "Offers & Updates"
        static let offersUpdatesFooter = "Product news, exclusive offers, and activity reminders."

        static let priceAlertsTitle = "Price Alerts"
        static let priceAlertsFooter = "Get notified about price changes for top market coins."

        static let allowNotificationsTitle = "Allow notifications"
        static let allowNotificationsDescription = "Push Notifications are enabled but won’t work until you allow notifications in your device settings."
        static let allowNotificationsButton = "Open Settings"
    }
}
