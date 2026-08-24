//
//  GachaCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class GachaCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Publishers

    @Published private(set) var state: ViewState?

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        switch options.destination {
        case .welcome:
            state = .welcome(GachaWelcomeViewModel())
        case .main:
            state = .main(GachaMainViewModel())
        }
    }
}

extension GachaCoordinator {
    struct Options {
        let destination: Destination

        enum Destination {
            case welcome
            case main
        }
    }

    enum ViewState {
        case welcome(GachaWelcomeViewModel)
        case main(GachaMainViewModel)
    }
}
