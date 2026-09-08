//
//  WalletFactoryProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct WalletFactoryProvider {
    let userWalletConfig: UserWalletConfig

    func makeWalletFactory(walletFactoryType: WalletFactoryType) -> AnyWalletFactory {
        switch walletFactoryType {
        case .owner:
            return userWalletConfig.makeAnyWalletFactory()
        case .joint(let safeAddress):
            return JointWalletFactory(
                defaultWalletFactory: userWalletConfig.makeAnyWalletFactory(),
                safeAddress: safeAddress
            )
        }
    }
}

extension WalletFactoryProvider {
    enum WalletFactoryType {
        case owner
        case joint(safeAddress: String?)
    }
}
