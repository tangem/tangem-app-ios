//
//  OverlayDeeplinkResponder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

/// Shows a deeplink over whatever is on screen. Lowest in the chain, so it only gets what the screen that could
/// show it natively didn't take, and it answers for whatever the presenter has a screen for.
final class OverlayDeeplinkResponder {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let coordinatorFactory = CommonMainCoordinatorChildFactory()

    /// The presenter outlives the presentation it starts: a screen whose data is still loading is shown by it
    /// later, and a screen it opened asks it to close.
    private lazy var presenter = DeeplinkPresenter(coordinatorFactory: coordinatorFactory)

    /// Scanning a card and unlocking a mobile wallet draw their own screen over everything the app has, and the
    /// user is busy holding a card to the phone. A link that arrives meanwhile waits for that to be over — the
    /// newest one, since the screen it opens is the answer to the last thing the user asked for. Once the card
    /// is away the link goes back to the chain rather than to the presenter here, so a link this responder has
    /// no screen for ends up where it would have without the wait.
    private var isScanningOrUnlocking = false
    private var waitingAction: DeeplinkNavigationAction?

    private var bag: Set<AnyCancellable> = []

    init() {
        bind()
    }
}

// MARK: - IncomingActionResponder

extension OverlayDeeplinkResponder: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        // Incoming actions are dispatched on the main thread, and so is everything a deeplink reads on its way
        // to a screen: wallet models, accounts, the presenter itself.
        MainActor.assumeIsolated { show(action) }
    }
}

// MARK: - Private

@MainActor
private extension OverlayDeeplinkResponder {
    func show(_ action: IncomingAction) -> Bool {
        guard case .navigation(let navigationAction) = action else {
            return false
        }

        guard !isScanningOrUnlocking else {
            waitingAction = navigationAction
            return true
        }

        guard presenter.present(navigationAction) else {
            return false
        }

        DeeplinkFloatingSheet.dismissActive()
        return true
    }

    func releaseWaitingAction() {
        guard let action = waitingAction else {
            return
        }

        waitingAction = nil
        incomingActionManager.deliver(.navigation(action))
    }
}

// MARK: - Bind

private extension OverlayDeeplinkResponder {
    func bind() {
        let didStart = Publishers.Merge(
            NotificationCenter.default.publisher(for: .cardSessionDidStart),
            NotificationCenter.default.publisher(for: .mobileUnlockDidStart)
        )
        .map { _ in true }

        let didFinish = Publishers.Merge(
            NotificationCenter.default.publisher(for: .cardSessionDidFinish),
            NotificationCenter.default.publisher(for: .mobileUnlockDidFinish)
        )
        .map { _ in false }

        Publishers.Merge(didStart, didFinish)
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { responder, isScanningOrUnlocking in
                responder.isScanningOrUnlocking = isScanningOrUnlocking

                if !isScanningOrUnlocking {
                    MainActor.assumeIsolated { responder.releaseWaitingAction() }
                }
            }
            .store(in: &bag)

        // A link held back for the card to be put away belongs to the session it arrived in. Locking ends that
        // session, and the screen it would open has no business appearing over the lock.
        userWalletRepository
            .eventProvider
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { responder, event in
                if case .locked = event {
                    responder.waitingAction = nil
                }
            }
            .store(in: &bag)
    }
}
