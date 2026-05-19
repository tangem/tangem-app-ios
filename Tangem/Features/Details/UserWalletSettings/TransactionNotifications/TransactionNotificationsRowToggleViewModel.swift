//
//  TransactionNotificationsRowToggleViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemLocalization
import TangemFoundation
import TangemUIUtils
import TangemAssets

final class TransactionNotificationsRowToggleViewModel: ObservableObject {
    // MARK: - Services

    @Injected(\.pushNotificationsPermission) var pushNotificationsPermission: PushNotificationsPermissionService

    // MARK: - Public Properties

    @Published var isPushNotifyEnabled: Bool

    // MARK: - ViewState

    @Published private(set) var warningPermissionViewModel: DefaultWarningRowViewModel?
    @Published private(set) var pushNotifyViewModel: DefaultToggleRowViewModel?

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

    private var requestAuthorizationTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = .init()

    // MARK: - Dependencies

    private let userTokensPushNotificationsManager: UserTokensPushNotificationsManager
    private weak var coordinator: TransactionNotificationsRowToggleRoutable?
    private let showPushSettingsAlert: (() -> Void)?

    // MARK: - Init

    init(
        userTokensPushNotificationsManager: UserTokensPushNotificationsManager,
        coordinator: TransactionNotificationsRowToggleRoutable?,
        showPushSettingsAlert: (() -> Void)?
    ) {
        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        self.coordinator = coordinator
        self.showPushSettingsAlert = showPushSettingsAlert

        isPushNotifyEnabled = userTokensPushNotificationsManager.status.isActive

        bind()
        setupViewModels()
    }

    func onTapMoreInfoTransactionPushNotifications() {
        coordinator?.openTransactionNotifications()
    }
}

// MARK: - Private

private extension TransactionNotificationsRowToggleViewModel {
    func bind() {
        userTokensPushNotificationsManager
            .statusPublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, status in
                viewModel.isPushNotifyEnabled = status.isActive
                viewModel.refreshPermissionWarning()
            }
            .store(in: &bag)
    }

    func setupViewModels() {
        // One-time initialization. Because isNotInitialized is non-recoverable
        pushNotifyViewModel = DefaultToggleRowViewModel(
            title: Localization.walletSettingsPushNotificationsTitle,
            isDisabled: userTokensPushNotificationsManager.status.isNotInitialized,
            isOn: isEnabledPushNotificationStatusBinding
        )

        refreshPermissionWarning()
    }
}

// MARK: - Private Push Notifications Implementation

private extension TransactionNotificationsRowToggleViewModel {
    func refreshPermissionWarning() {
        // Warning is relevant only when push notifications are switched on remotely
        // but the user has revoked (or never granted) the iOS system permission.
        let shouldShowPermissionWarning = userTokensPushNotificationsManager.status == .needSystemPermission && userTokensPushNotificationsManager.isRemoteStatusEnabled

        guard shouldShowPermissionWarning else {
            warningPermissionViewModel = nil
            return
        }

        warningPermissionViewModel = DefaultWarningRowViewModel(
            title: Localization.transactionNotificationsWarningTitle,
            subtitle: Localization.transactionNotificationsWarningDescription,
            leftView: .icon(Assets.attention),
        )
    }

    /// Handles the state changes of push notifications toggle in wallet settings.
    ///
    /// This method manages the transition between different push notification states based on the current status
    /// and the requested value. It handles special cases such as system permission blocks and provides
    /// appropriate user feedback through alerts when necessary.
    ///
    /// - Parameter value: The new desired state of push notifications (true for enabled, false for disabled)
    ///
    /// The method follows these rules:
    /// - For .enabled or .disabledInApp states: Simply switches between these states based on the remote server value
    /// - For .needSystemPermission state:
    ///   - If enabling: Shows an alert to guide user to system settings
    ///   - If disabling: No action needed (already disabled)
    /// - For other states (`.loading`, `.failed`): Maintains current status and UI shows toggle as disabled
    ///
    /// The actual status update is delegated to the userTokensPushNotificationsManager.
    func handleTogglePushNotifyStatus(toggleValue: Bool) {
        Analytics.log(.pushToggleClicked, params: [.state: toggleValue ? .on : .off])

        switch userTokensPushNotificationsManager.status {
        case .enabled, .disabledInApp:
            userTokensPushNotificationsManager.process(.handleUpdateStatus(toggleValue))
        case .needSystemPermission where toggleValue:
            handleAndCheckUnavailablePushNotifyStatus()
            return
        case .needSystemPermission where !toggleValue:
            break
        default:
            // DefaultToggleRowViewModel did at disabled state. The status does not need to be updated
            break
        }
    }

    func handleAndCheckUnavailablePushNotifyStatus() {
        requestAuthorizationTask?.cancel()

        requestAuthorizationTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.pushNotificationsPermission.requestAuthorizationAndRegister()

            if await viewModel.pushNotificationsPermission.isAuthorized {
                viewModel.userTokensPushNotificationsManager.process(.handleUpdateStatus(true))
            } else {
                // To display a system message about the need for permission to receive notifications.
                viewModel.showPushSettingsAlert?()
                return
            }
        }
    }
}
