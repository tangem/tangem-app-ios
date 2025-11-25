//
//  AccountsAwareWalletModelsFactoryInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol AccountsAwareWalletModelsFactoryInput {
    func setCryptoAccount(_ cryptoAccount: any CryptoAccountModel)
}
