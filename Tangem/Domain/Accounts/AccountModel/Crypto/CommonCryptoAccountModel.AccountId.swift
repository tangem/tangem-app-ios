//
//  CommonCryptoAccountModel.AccountId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

extension CommonCryptoAccountModel {
    /// A specific identifier for the `CryptoAccountModel` type only. Other types of accounts must implement and use different id types.
    struct AccountId: Hashable {
        /// - Note: For serialization/deserialization purposes and backend communications.
        var rawValue: Data {
            let bytes = userWalletId.value + derivationIndex.bytes4

            return bytes.getSha256()
        }

        private let userWalletId: UserWalletId
        private let derivationIndex: Int

        init(
            userWalletId: UserWalletId,
            derivationIndex: Int
        ) {
            self.userWalletId = userWalletId
            self.derivationIndex = derivationIndex
        }
    }
}

extension CommonCryptoAccountModel.AccountId: AccountModelPersistentIdentifierConvertible {
    func toPersistentIdentifier() -> Int {
        return derivationIndex
    }
}
