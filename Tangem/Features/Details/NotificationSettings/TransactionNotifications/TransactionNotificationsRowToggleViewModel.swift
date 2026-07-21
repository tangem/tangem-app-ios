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
    // MARK: - Public Properties

    @Published var isPushNotifyEnabled: Bool

    // MARK: - ViewState

    @Published private(set) var warningPermissionViewModel: DefaultWarningRowViewModel?
    @Published private(set) var pushNotifyViewModel: DefaultToggleRowViewModel?

    /// Mirror of the interactor's permission flag, kept only to derive the permission warning.
    private var isSystemPermissionGranted: Bool = false

    private var isEnabledPushNotificationStatusBinding: BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.isPushNotifyEnabled },
            set: { viewModel, value in
                viewModel.isPushNotifyEnabled = value
                viewModel.handleToggle(value: value)
            }
        )
    }

    // MARK: - Dependencies

    private let userTokensPushNotificationsManager: UserTokensPushNotificationsManager
    private weak var coordinator: TransactionNotificationsRowToggleRoutable?
    private let showPushSettingsAlert: (() -> Void)?

    /// Shared push-settings toggle flow (pending enable + system-permission handling).
    private lazy var toggleInteractor = PushChannelToggleInteractor(
        userTokensPushNotificationsManager: userTokensPushNotificationsManager,
        output: self
    )

    private var bag: Set<AnyCancellable> = .init()

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

        setupViewModels()
        bind()
    }

    // MARK: - Lifecycle

    func onAppear() {
        toggleInteractor.refreshSystemPermissionState()
    }

    func onTapMoreInfoTransactionPushNotifications() {
        coordinator?.openTransactionNotifications()
    }
}

// MARK: - Private

private extension TransactionNotificationsRowToggleViewModel {
    func bind() {
        // System permission (owned by the interactor) and remote status both feed into banner
        // visibility and toggle state, so we recompute the UI whenever either of them changes.
        Publishers.CombineLatest(
            toggleInteractor.isSystemPermissionGrantedPublisher.removeDuplicates(),
            userTokensPushNotificationsManager.statusPublisher.removeDuplicates()
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { viewModel, values in
            viewModel.isSystemPermissionGranted = values.0
            viewModel.refreshUI()
        }
        .store(in: &bag)
    }

    func setupViewModels() {
        rebuildPushNotifyViewModel()
    }

    func refreshUI() {
        isPushNotifyEnabled = userTokensPushNotificationsManager.isRemoteStatusEnabled
        rebuildPushNotifyViewModel()
        refreshPermissionWarning()
    }

    func rebuildPushNotifyViewModel() {
        let isDisabled = userTokensPushNotificationsManager.status.isNotInitialized

        guard pushNotifyViewModel?.isDisabled != isDisabled else {
            return
        }

        pushNotifyViewModel = DefaultToggleRowViewModel(
            title: Localization.walletSettingsPushNotificationsTitle,
            isDisabled: isDisabled,
            isOn: isEnabledPushNotificationStatusBinding
        )
    }

    /// Banner is shown when push notifications are switched on remotely but the user has revoked
    /// (or never granted) the iOS system permission.
    func refreshPermissionWarning() {
        let shouldShowPermissionWarning = !isSystemPermissionGranted && userTokensPushNotificationsManager.isRemoteStatusEnabled

        guard shouldShowPermissionWarning else {
            warningPermissionViewModel = nil
            return
        }

        warningPermissionViewModel = DefaultWarningRowViewModel(
            title: Localization.transactionNotificationsWarningTitle,
            subtitle: Localization.transactionNotificationsWarningDescription,
            leftView: .icon(Assets.attention)
        )
    }
}

// MARK: - Toggle Handling

private extension TransactionNotificationsRowToggleViewModel {
    /// Optimistically updates the UI (via the binding setter), then delegates the permission-aware
    /// channel update to `PushChannelToggleInteractor`.
    func handleToggle(value: Bool) {
        Analytics.log(.pushToggleClicked, params: [.state: value ? .on : .off])

        toggleInteractor.toggle(value, for: .transactionAlerts)
    }
}

// MARK: - PushChannelToggleInteractorOutput

extension TransactionNotificationsRowToggleViewModel: PushChannelToggleInteractorOutput {
    func revertToggle(for channel: PushChannel) {
        isPushNotifyEnabled = false
    }

    /// The alert is owned by the hosting screen and intentionally leaves the pending enable in
    /// place: it points the user at iOS Settings, and if they return with permission granted,
    /// `isAuthorizedPublisher` fires `true` and the interactor executes the pending enable
    /// automatically.
    func presentEnablePushSettingsAlert(for channel: PushChannel) {
        showPushSettingsAlert?()
    }

    /// On failure the manager still holds the last synced remote state; re-reading it through
    /// `refreshUI()` rolls the toggle back (this row shows no error alert).
    func handlePreferenceUpdateFailure(for channel: PushChannel) {
        refreshUI()
    }
}
