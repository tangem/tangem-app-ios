//
//  CryptoAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// - Warning: An abstract protocol, DO NOT conform to it directly, conform to one of its refinements instead.
protocol CryptoAccountModel: BaseAccountModel, AccountModelEditable, BalanceProvidingAccountModel, DisposableEntity, AnyObject where Icon == AccountModel.CompositeIcon, ID == CryptoAccountModelId, Editor: AccountModelEditor {
    var isMainAccount: Bool { get }

    var accountType: AccountType { get }

    var descriptionString: String { get }

    var walletModelsManager: WalletModelsManager { get }

    var userTokensManager: UserTokensManager { get }

    func archive() async throws(AccountArchivationError)
}
