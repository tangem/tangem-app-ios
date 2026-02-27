//
//  NavigationActions.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol NavigationActions {
    var actionPublisher: AnyPublisher<NavigationAction, Never> { get }
}

public enum NavigationAction {
    case push(route: NavigationRoutable, animated: Bool)
    case pop(animated: Bool)
    case popToRoot(animated: Bool)
}
