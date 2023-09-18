//
//  WalletSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class WalletSelectorCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>
    let output: WalletSelectorCoordinatorOutput

    // MARK: - Published

    @Published private(set) var walletSelectorViewModel: WalletSelectorViewModel? = nil

    // MARK: - Init

    required init(output: WalletSelectorCoordinatorOutput, dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.output = output
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Implmentation

    func start(with options: WalletSelectorCoordinator.Options) {
        walletSelectorViewModel = .init(userWallets: options.userWallets, currentUserWalletId: options.currentUserWalletId, coordinator: self)
    }
}

extension WalletSelectorCoordinator {
    struct Options {
        let userWallets: [UserWallet]
        let currentUserWalletId: Data
    }
}

extension WalletSelectorCoordinator: WalletSelectorRoutable {
    func didSelectWallet(with userWalletId: Data) {
        output.didSelectWallet(with: userWalletId)
    }
}
