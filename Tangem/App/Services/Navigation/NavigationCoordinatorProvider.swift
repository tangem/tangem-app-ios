//
//  NavigationCoordinatorProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct NavigationCoordinatorProvider: NavigationCoordinatorProviding {
    private(set) var coordinator: NavigationCoordinator = .init()
}
