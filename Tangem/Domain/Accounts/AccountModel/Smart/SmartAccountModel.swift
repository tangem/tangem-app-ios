//
//  SmartAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@available(*, unavailable, message: "This account type is not implemented yet")
protocol SmartAccountModel: BaseAccountModel {}

// MARK: - AccountModelResolvable protocol conformance

@available(*, unavailable, message: "This account type is not implemented yet")
extension SmartAccountModel {
    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }
}
