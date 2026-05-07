//
//  WalletConnectPayCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

final class WalletConnectPayCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @MainActor
    @Published private(set) var viewModel: WalletConnectPayViewModel?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            viewModel = WalletConnectPayModuleFactory.makePayViewModel(for: options.link)
            viewModel?.loadPaymentOptions()
        }
    }
}

extension WalletConnectPayCoordinator {
    struct Options {
        let link: WalletConnectPayLink
    }
}
