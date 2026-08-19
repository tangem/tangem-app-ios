//
//  PushChannelToggleInteractor.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// UI effects the interactor delegates back to the owning view model. Screens react differently
/// (e.g. an error alert vs. silently re-syncing the toggle from the manager state), so the
/// interactor only reports the events.
@MainActor
protocol PushChannelToggleInteractorOutput: AnyObject {
    func revertToggle(for channel: PushChannel)
    func presentEnablePushSettingsAlert(for channel: PushChannel)
    func handlePreferenceUpdateFailure(for channel: PushChannel)
}

/// Channel-toggle flow extracted from the push notification settings screen so other screens
/// (e.g. the Price Alerts screen) reuse the exact same behavior:
/// - Optimistic UI update happens in the view model; on backend failure the manager's
///   `preferencesPublisher` rolls the toggle back and the interactor reports the error.
/// - When enabling while system permission is not granted, the interactor switches into a pending
///   state and requests iOS authorization. The final decision is primarily processed from
///   `isAuthorizedPublisher` (e.g. the user returns from system Settings); if iOS doesn't surface
///   a system prompt anymore (already denied), it falls back to asking the output to show the
///   settings alert while keeping the pending state.
final class PushChannelToggleInteractor {
    @Injected(\.pushNotificationsPermission) private var pushNotificationsPermission: PushNotificationsPermissionService

    private let userWalletPushNotificationsManager: UserWalletPushNotificationsManager
    private weak var output: PushChannelToggleInteractorOutput?

    /// Single source of truth for the iOS system permission flag. Owning screens observe
    /// `isSystemPermissionGrantedPublisher` instead of keeping their own copy. Starts at `.idle`
    /// so the UI doesn't react to a placeholder `false` before the first real reading — otherwise
    /// the "allow notifications" banner flashes on screen open.
    @Published private var authorizationState: AuthorizationState = .idle
    private var pendingEnableChannel: PushChannel?
    private var toggleTasks: [PushChannel: Task<Void, Never>] = [:]
    private var bag = Set<AnyCancellable>()

    /// Emits only real permission readings — `.idle` is dropped so consumers never see a fake `false`.
    var isSystemPermissionGrantedPublisher: AnyPublisher<Bool, Never> {
        $authorizationState
            .compactMap { state in
                switch state {
                case .idle: return nil
                case .value(let isAuthorized): return isAuthorized
                }
            }
            .eraseToAnyPublisher()
    }

    private var isSystemPermissionGranted: Bool {
        switch authorizationState {
        case .idle: false
        case .value(let isAuthorized): isAuthorized
        }
    }

    init(
        userWalletPushNotificationsManager: UserWalletPushNotificationsManager,
        output: PushChannelToggleInteractorOutput
    ) {
        self.userWalletPushNotificationsManager = userWalletPushNotificationsManager
        self.output = output

        bind()
    }

    /// User toggled the switch for the given channel (UI intent). The view model flips its own
    /// published state optimistically before calling this.
    func toggle(_ value: Bool, for channel: PushChannel) {
        toggleTasks[channel]?.cancel()

        toggleTasks[channel] = runTask(in: self) { @MainActor interactor in
            if value, !interactor.isSystemPermissionGranted {
                interactor.pendingEnableChannel = channel

                // The awaits below aren't cooperatively cancellable, so guard explicitly after each:
                // a superseding toggle cancels this task but can't stop these calls from resuming,
                // and the resumed continuation would otherwise mutate pending state out of order.
                await interactor.pushNotificationsPermission.requestAuthorizationAndRegister()
                guard !Task.isCancelled else { return }

                // If iOS prompt wasn't shown, `isAuthorizedPublisher` may not emit.
                // Resolve pending state from a direct snapshot in this fallback path.
                let isAuthorized = await interactor.pushNotificationsPermission.isAuthorized
                guard !Task.isCancelled else { return }

                interactor.handlePendingEnableAuthorizationUpdate(
                    isAuthorized: isAuthorized,
                    source: .authorizationRequestFallback
                )
                return
            }

            if !value, interactor.pendingEnableChannel == channel {
                interactor.pendingEnableChannel = nil
            }

            // Don't start a backend write for a task that was already superseded by a newer toggle.
            guard !Task.isCancelled else { return }

            do {
                try await interactor.userWalletPushNotificationsManager.tryUpdateEnableState(value: value, for: channel)
            } catch is CancellationError {
                return
            } catch {
                interactor.output?.handlePreferenceUpdateFailure(for: channel)
            }
        }
    }

    /// The user dismissed the enable-in-settings alert without granting permission; drops the
    /// pending enable so a later `isAuthorizedPublisher` emission doesn't re-enable the channel.
    func cancelPendingEnable(for channel: PushChannel) {
        if pendingEnableChannel == channel {
            pendingEnableChannel = nil
        }
    }

    /// Pulls the current system authorization status into the interactor. Call from the screen's
    /// `onAppear` — `isAuthorizedPublisher` only emits on `UIApplication.didBecomeActive`, so the
    /// initial state must be primed explicitly.
    func refreshSystemPermissionState() {
        runTask(in: self) { @MainActor interactor in
            interactor.authorizationState = .value(await interactor.pushNotificationsPermission.isAuthorized)
        }
    }
}

// MARK: - Private

private extension PushChannelToggleInteractor {
    /// `.idle` means no permission reading has been observed yet — consumers must drop it instead
    /// of treating it as `false`.
    enum AuthorizationState: Hashable {
        case idle
        case value(Bool)
    }

    enum PendingEnableAuthorizationUpdateSource {
        case isAuthorizedPublisher
        case authorizationRequestFallback
    }

    func bind() {
        // `isAuthorizedPublisher` only emits on `UIApplication.didBecomeActive`, so this branch
        // covers the case when the user returns from system Settings. `.receiveOnMain()` guarantees
        // this sink runs on the main thread, so `assumeIsolated` calls into the `@MainActor` update
        // synchronously — no Task hop, so the permission-flag write and the resulting revert/alert/
        // auto-enable stay atomic with no window for a concurrent toggle to interleave.
        pushNotificationsPermission.isAuthorizedPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { interactor, isAuthorized in
                MainActor.assumeIsolated {
                    interactor.authorizationState = .value(isAuthorized)
                    interactor.handlePendingEnableAuthorizationUpdate(
                        isAuthorized: isAuthorized,
                        source: .isAuthorizedPublisher
                    )
                }
            }
            .store(in: &bag)
    }

    @MainActor
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
            output?.revertToggle(for: channel)
        case .authorizationRequestFallback:
            // Intentionally keep the pending state: the alert points the user at iOS Settings, and
            // if they return with permission granted, `isAuthorizedPublisher` fires `true` and the
            // branch above executes the pending enable automatically.
            output?.presentEnablePushSettingsAlert(for: channel)
        }
    }

    func tryEnablePendingChannel(_ channel: PushChannel) {
        toggleTasks[channel]?.cancel()
        toggleTasks[channel] = runTask(in: self) { @MainActor interactor in
            do {
                try await interactor.userWalletPushNotificationsManager.tryUpdateEnableState(value: true, for: channel)
            } catch is CancellationError {
                return
            } catch {
                interactor.output?.handlePreferenceUpdateFailure(for: channel)
            }
        }
    }
}
