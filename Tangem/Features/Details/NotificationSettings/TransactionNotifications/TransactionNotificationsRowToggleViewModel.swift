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

    @Published private var isSystemPermissionGranted: Bool = false

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

    // MARK: - Pending state

    private var pendingEnable: Bool = false
    private var toggleTask: Task<Void, Never>?
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
        refreshSystemPermissionState()
    }

    func onTapMoreInfoTransactionPushNotifications() {
        coordinator?.openTransactionNotifications()
    }
}

// MARK: - Private

private extension TransactionNotificationsRowToggleViewModel {
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

        // System permission and remote status both feed into banner visibility and toggle state,
        // so we recompute the UI whenever either of them changes.
        Publishers.CombineLatest(
            $isSystemPermissionGranted.removeDuplicates(),
            userTokensPushNotificationsManager.statusPublisher.removeDuplicates()
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { viewModel, _ in
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

    /// Pulls the current system authorization status and writes it into `isSystemPermissionGranted`,
    /// which in turn drives `refreshUI()` through the `$isSystemPermissionGranted` subscription
    /// in `bind()`. Called on screen appearance to avoid waiting for the next `didBecomeActive`.
    func refreshSystemPermissionState() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            isSystemPermissionGranted = await pushNotificationsPermission.isAuthorized
        }
    }
}

// MARK: - Toggle Handling

private extension TransactionNotificationsRowToggleViewModel {
    /// Optimistically updates the UI (via the binding setter), then forwards the request to the
    /// manager. When trying to enable while system permission is not granted, we switch into a
    /// pending state and request iOS authorization. The final decision is primarily processed
    /// from `isAuthorizedPublisher`; if iOS doesn't surface a system prompt anymore (already
    /// denied), we fall back to showing our own settings alert.
    func handleToggle(value: Bool) {
        Analytics.log(.pushToggleClicked, params: [.state: value ? .on : .off])

        toggleTask?.cancel()

        toggleTask = Task { @MainActor [weak self] in
            guard let self else { return }

            if value, !isSystemPermissionGranted {
                pendingEnable = true

                // The awaits below aren't cooperatively cancellable, so guard explicitly after each:
                // a superseding toggle cancels this task but can't stop these calls from resuming,
                // and the resumed continuation would otherwise mutate pending state out of order.
                await pushNotificationsPermission.requestAuthorizationAndRegister()
                guard !Task.isCancelled else { return }

                // If iOS prompt wasn't shown (already-denied), `isAuthorizedPublisher` may not emit.
                // Resolve pending state from a direct snapshot in this fallback path.
                let isAuthorized = await pushNotificationsPermission.isAuthorized
                guard !Task.isCancelled else { return }

                handlePendingEnableAuthorizationUpdate(
                    isAuthorized: isAuthorized,
                    source: .authorizationRequestFallback
                )
                return
            }

            if !value, pendingEnable {
                pendingEnable = false
            }

            // Don't start a backend write for a task that was already superseded by a newer toggle.
            guard !Task.isCancelled else { return }

            await updateEnableState(value)
        }
    }

    func handlePendingEnableAuthorizationUpdate(
        isAuthorized: Bool,
        source: PendingEnableAuthorizationUpdateSource
    ) {
        guard pendingEnable else {
            return
        }

        if isAuthorized {
            pendingEnable = false
            tryEnablePending()
            return
        }

        switch source {
        case .isAuthorizedPublisher:
            pendingEnable = false
            revertToggle()
        case .authorizationRequestFallback:
            // Intentionally keep `pendingEnable = true`: the alert points the user at iOS Settings,
            // and if they return with permission granted, `isAuthorizedPublisher` will fire `true`
            // and the `.isAuthorizedPublisher` branch above will execute the pending enable
            // automatically.
            showPushSettingsAlert?()
        }
    }

    func tryEnablePending() {
        toggleTask?.cancel()
        toggleTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await updateEnableState(true)
        }
    }

    /// On failure the `statusPublisher` subscription rolls the toggle back through `refreshUI()`.
    func updateEnableState(_ value: Bool) async {
        do {
            try await userTokensPushNotificationsManager.tryUpdateEnableState(value: value, for: .transactionAlerts)
        } catch is CancellationError {
            return
        } catch {
            refreshUI()
        }
    }

    func revertToggle() {
        isPushNotifyEnabled = false
    }
}
