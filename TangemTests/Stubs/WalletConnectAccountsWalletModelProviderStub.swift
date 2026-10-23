//
//  WalletConnectAccountsWalletModelProviderStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@testable import Tangem

struct WalletConnectAccountsWalletModelProviderStub: WalletConnectAccountsWalletModelProvider {
    let walletModel: any WalletModel

    func getModel(with address: String, blockchainId: String, accountId: String) throws -> any WalletModel {
        walletModel
    }

    func getModels(with blockchainId: String, accountId: String) -> [any WalletModel] {
        [walletModel]
    }

    func getModel(with blockchainId: String, accountId: String) -> (any WalletModel)? {
        walletModel
    }
}
