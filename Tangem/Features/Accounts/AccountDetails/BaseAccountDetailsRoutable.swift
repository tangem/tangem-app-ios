//
//  BaseAccountDetailsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol BaseAccountDetailsRoutable: AnyObject {
    func close()
}

protocol CryptoAccountDetailsRoutable: AnyObject {
    func editAccount()
    func manageTokens()
}
