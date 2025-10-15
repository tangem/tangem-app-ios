//
//  CryptoAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemNFT

protocol CryptoAccountModel: BaseAccountModel, BalanceProvidingAccountModel, AnyObject {
    var isMainAccount: Bool { get }

    var descriptionString: String { get }

    var walletModelsManager: WalletModelsManager { get }

    var userTokensManager: UserTokensManager { get }

    // [REDACTED_TODO_COMMENT]
    @available(iOS, deprecated: 100000.0, message: "Probably will be removed from the public interface, rewritten from scratch and used only internally")
    var userTokenListManager: UserTokenListManager { get }
}
