//
//  VisaAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@available(*, unavailable, message: "This account type is not implemented yet")
protocol VisaAccountModel: BaseAccountModel, AccountModelResolvable {}

// MARK: - AccountModelResolvable protocol conformance

@available(*, unavailable, message: "This account type is not implemented yet")
extension VisaAccountModel {
    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }
}
