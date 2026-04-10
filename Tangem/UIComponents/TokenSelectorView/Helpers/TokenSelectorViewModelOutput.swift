//
//  TokenSelectorViewModelOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol TokenSelectorViewModelOutput: AnyObject {
    func userDidSelect(item: TokenSelectorItem)
}
