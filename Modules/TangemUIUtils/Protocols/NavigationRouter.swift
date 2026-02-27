//
//  NavigationRouter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol NavigationRouter {
    func push(route: NavigationRoutable, animated: Bool)
    func push(route: NavigationRoutable)
    func pop(animated: Bool)
    func pop()
    func popToRoot(animated: Bool)
    func popToRoot()
}

public protocol NavigationRoutable: Hashable {}

public extension NavigationRouter {
    func push(route: NavigationRoutable) {
        push(route: route, animated: true)
    }

    func pop() {
        pop(animated: true)
    }

    func popToRoot() {
        popToRoot(animated: true)
    }
}
