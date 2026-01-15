//
//  AccountsAwareTokenSelectorViewModelOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol AccountsAwareTokenSelectorViewModelOutput: AnyObject {
    func usedDidSelect(item: AccountsAwareTokenSelectorItem)
}
