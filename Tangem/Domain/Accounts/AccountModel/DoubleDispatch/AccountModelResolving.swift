//
//  AccountModelResolving.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol AccountModelResolving {
    associatedtype Result
    
    func resolve(accountModel: any CryptoAccountModel) -> Result
    func resolve(accountModel: any SmartAccountModel) -> Result
    func resolve(accountModel: any VisaAccountModel) -> Result
}
