//
//  NavigationCoordinatorProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol NavigationCoordinatorProviding { //[REDACTED_TODO_COMMENT]
    var coordinator: NavigationCoordinator { get }
}
 
private struct NavigationCoordinatorProviderKey: InjectionKey {
    static var currentValue: NavigationCoordinatorProviding = NavigationCoordinatorProvider()
}

extension InjectedValues {
    var navigationCoordinatorProvider: NavigationCoordinatorProviding {
        get { Self[NavigationCoordinatorProviderKey.self] }
        set { Self[NavigationCoordinatorProviderKey.self] = newValue }
    }
}

