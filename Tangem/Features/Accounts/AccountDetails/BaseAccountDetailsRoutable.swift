//
//  BaseAccountDetailsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol BaseAccountDetailsRoutable: AnyObject {
    func editAccount()
    func close()
}

protocol CryptoAccountDetailsRoutable: AnyObject {
    func manageTokens()
}
