//
//  CryptoAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CryptoAccountModel: BaseAccountModel, BalanceProvidingAccountModel, AnyObject {
    var isMainAccount: Bool { get }

    var descriptionString: String { get }

    var walletModelsManager: WalletModelsManager { get }

    var userTokensManager: UserTokensManager { get }

    func archive() async throws(AccountArchivationError)
}

// MARK: - AccountModelResolvable protocol conformance

extension CryptoAccountModel {
    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }
}
