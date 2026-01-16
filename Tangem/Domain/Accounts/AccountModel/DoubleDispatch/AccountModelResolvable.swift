//
//  AccountModelResolvable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AccountModelResolvable {
    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving
}
