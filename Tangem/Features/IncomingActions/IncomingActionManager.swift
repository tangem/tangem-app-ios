//
//  IncomingActionManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import Foundation

typealias IncomingActionManager = IncomingActionHandler & IncomingActionManaging

protocol IncomingActionHandler {
    /// Whether someone took the link. A caller that has nothing else to do with the link may ignore the answer.
    @discardableResult
    func handleIncomingURL(_ url: URL) -> Bool
    func handleIntent(_ intent: String) -> Bool
}

/// Object's interface for encapsulating logic of deeplink handling
protocol IncomingActionManaging: AnyObject {
    /// Every action as it arrives, before the chain is asked — for whoever needs to know a link came in
    /// regardless of what, if anything, shows it. Delivered in the turn it arrived in: a subscriber that
    /// switches schedulers no longer gets there before the chain, and a destination may be gated on it.
    var incomingActionsPublisher: AnyPublisher<IncomingAction, Never> { get }

    func becomeFirstResponder(_ responder: IncomingActionResponder)
    func resignFirstResponder(_ responder: IncomingActionResponder)
    /// Hands an action to the chain as if it had just arrived: whoever can show it now does.
    func deliver(_ action: IncomingAction)
}

protocol IncomingActionResponder: AnyObject {
    /// Asks responder to handle route. If it returns `true`, previous responders are not called.
    /// If it returns `false`, previous responder is called to handle route.
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool
}

// MARK: - Dependencies

private struct IncomingActionManagerKey: InjectionKey {
    static var currentValue: IncomingActionManager = CommonIncomingActionManager()
}

extension InjectedValues {
    var incomingActionHandler: IncomingActionHandler {
        manager
    }

    var incomingActionManager: IncomingActionManaging {
        manager
    }

    private var manager: IncomingActionManager {
        get { Self[IncomingActionManagerKey.self] }
        set { Self[IncomingActionManagerKey.self] = newValue }
    }
}
