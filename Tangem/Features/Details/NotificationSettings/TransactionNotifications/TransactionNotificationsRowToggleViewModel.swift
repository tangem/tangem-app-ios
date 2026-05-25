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

        isPushNotifyEnabled = userTokensPushNotificationsManager.isRemoteStatusEnabled

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
                viewModel.applyPushNotifyStatus(status)
            }
            .store(in: &bag)
    }

    func setupViewModels() {
        applyPushNotifyStatus(userTokensPushNotificationsManager.status)
    }

    func applyPushNotifyStatus(_ status: UserWalletPushNotifyStatus) {
        isPushNotifyEnabled = userTokensPushNotificationsManager.isRemoteStatusEnabled
        updatePushNotifyViewModel(isDisabled: status.isNotInitialized)
        refreshPermissionWarning()
    }

    func updatePushNotifyViewModel(isDisabled: Bool) {
        guard pushNotifyViewModel?.isDisabled != isDisabled else {
            return
        }

        pushNotifyViewModel = DefaultToggleRowViewModel(
            title: Localization.walletSettingsPushNotificationsTitle,
            isDisabled: isDisabled,
            isOn: isEnabledPushNotificationStatusBinding
        )
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
    /// - For .enabled or .disabledInApp states: Updates remote preference via the manager
    /// - For .needSystemPermission state:
    ///   - If enabling: Requests system permission, then enables remote when granted
    ///   - If disabling: Turns off remote preference even without system permission
    /// - For other states (`.loading`, `.failed`): Maintains current status and UI shows toggle as disabled
    ///
    /// The actual status update is delegated to the userTokensPushNotificationsManager.
    func handleTogglePushNotifyStatus(toggleValue: Bool) {
        Analytics.log(.pushToggleClicked, params: [.state: toggleValue ? .on : .off])

        switch userTokensPushNotificationsManager.status {
        case .enabled:
            userTokensPushNotificationsManager.tryUpdateEnableState(value: toggleValue)
        case .disabledInApp where toggleValue:
            handleAndCheckUnavailablePushNotifyStatus()
        case .disabledInApp:
            userTokensPushNotificationsManager.tryUpdateEnableState(value: false)
        case .needSystemPermission where !toggleValue:
            userTokensPushNotificationsManager.tryUpdateEnableState(value: false)
        case .loading, .failed:
            break
        case .needSystemPermission:
            handleAndCheckUnavailablePushNotifyStatus()
        }

        applyPushNotifyStatus(userTokensPushNotificationsManager.status)
    }

    func handleAndCheckUnavailablePushNotifyStatus() {
        requestAuthorizationTask?.cancel()

        requestAuthorizationTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.pushNotificationsPermission.requestAuthorizationAndRegister()

            if await viewModel.pushNotificationsPermission.isAuthorized {
                viewModel.userTokensPushNotificationsManager.tryUpdateEnableState(value: true)
            } else {
                // To display a system message about the need for permission to receive notifications.
                viewModel.showPushSettingsAlert?()
                return
            }
        }
    }
}
