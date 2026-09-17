//
//  AppSessionDeeplinkResponders.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

/// Who shows a deeplink that belongs to no single screen, for how long each of them is asked, and what happens
/// to a link that arrives while no one is there to show it.
final class AppSessionDeeplinkResponders {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.wcService) private var wcService: any WCService

    private let externalLinkResponder = ExternalLinkDeeplinkResponder()
    private let overlayResponder = OverlayDeeplinkResponder()
    private let campaignResponder = CampaignDeeplinkResponder()
    private let tangemPayTransactionResponder = TangemPayTransactionDeeplinkResponder()
    private let surveyResponder = SurveyDeeplinkResponder()

    private var bag: Set<AnyCancellable> = []

    /// Registered back to front: the chain asks the last registered first, so this list reads from the answer
    /// of last resort to the one tried first.
    ///
    /// One thing a new entry has to decide for itself: whether it shows a floating sheet. If it shows anything
    /// else, it calls `DeeplinkFloatingSheet.dismissActive()` first, or an open sheet covers what it shows.
    /// A sheet of its own is enqueued as it is — that queue is the presenter's business.
    private var sessionResponders: [any IncomingActionResponder] {
        [
            externalLinkResponder,
            overlayResponder,
            campaignResponder,
            tangemPayTransactionResponder,
            surveyResponder,
            wcService,
        ]
    }

    /// The one link that arrived while no session was on screen — the launch, unlock or welcome screen — kept
    /// for the main screen to pick up when it first appears. A newer one takes its place.
    private var waitingAction: IncomingAction?

    func start() {
        standAtTheDoor()

        // The lock screen lies over the main screen instead of replacing it, so the session responders have to
        // be told to leave rather than waiting for a change of state.
        userWalletRepository
            .eventProvider
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { responders, event in
                if case .locked = event {
                    responders.endSession()
                }
            }
            .store(in: &bag)
    }

    /// Whoever shows a deeplink over the wallet session is in the chain for exactly as long as the session is
    /// on screen and open. Inside a session nothing waits: a link is shown now or it is gone. What waited at
    /// the door until this moment is the main screen's to take, right after.
    func beginSession() {
        incomingActionManager.resignFirstResponder(self)
        sessionResponders.forEach { incomingActionManager.becomeFirstResponder($0) }
    }

    func endSession() {
        sessionResponders.forEach { incomingActionManager.resignFirstResponder($0) }
        standAtTheDoor()
    }

    /// Hands over what waited at the door, once.
    func takeWaitingAction() -> IncomingAction? {
        defer { waitingAction = nil }
        return waitingAction
    }
}

// MARK: - The door

private extension AppSessionDeeplinkResponders {
    /// With no session on screen this object is what the chain holds: it keeps the newest link for the main
    /// screen. Taken out and put back so that it ends up on top whatever the chain held before — the manager
    /// keeps an already registered responder where it was.
    func standAtTheDoor() {
        incomingActionManager.resignFirstResponder(self)
        incomingActionManager.becomeFirstResponder(self)
    }
}

// MARK: - IncomingActionResponder

extension AppSessionDeeplinkResponders: IncomingActionResponder {
    /// A screen of the wallet session still means something once the session is up. Unlocking the app and the
    /// browser's own callback belong to the moment they arrive in and are of no use after it.
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        switch action {
        case .start, .dismissSafari:
            return false
        case .navigation, .externalLink, .walletConnect:
            AppLogger.info("Incoming action waits for the main screen: \(action)")
            waitingAction = action
            return true
        }
    }
}
