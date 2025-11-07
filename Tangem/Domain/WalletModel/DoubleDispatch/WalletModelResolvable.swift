//
//  WalletModelResolvable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletModelResolvable {
    func resolve<R>(using resolver: R) -> R.Result where R: WalletModelResolving
}
