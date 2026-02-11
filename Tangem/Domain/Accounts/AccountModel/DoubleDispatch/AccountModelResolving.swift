//
//  AccountModelResolving.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AccountModelResolving {
    associatedtype Result

    func resolve(accountModel: any CryptoAccountModel) -> Result

    // Uncomment when this account type is added
    #if false
    func resolve(accountModel: any SmartAccountModel) -> Result
    #endif // false

    // Uncomment when this account type is added
    #if false
    func resolve(accountModel: any VisaAccountModel) -> Result
    #endif // false
}
