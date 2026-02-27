//
//  NavigationRouter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUIUtils

public final class CommonNavigationRouter: NavigationRouter, NavigationActions {
    public let actionPublisher: AnyPublisher<NavigationAction, Never>

    private let actionSubject = PassthroughSubject<NavigationAction, Never>()

    public init() {
        actionPublisher = actionSubject.eraseToAnyPublisher()
    }

    public func push(route: NavigationRoutable, animated: Bool) {
        let action = NavigationAction.push(route: route, animated: animated)
        actionSubject.send(action)
    }

    public func pop(animated: Bool) {
        let action = NavigationAction.pop(animated: animated)
        actionSubject.send(action)
    }

    public func popToRoot(animated: Bool) {
        let action = NavigationAction.popToRoot(animated: animated)
        actionSubject.send(action)
    }
}
