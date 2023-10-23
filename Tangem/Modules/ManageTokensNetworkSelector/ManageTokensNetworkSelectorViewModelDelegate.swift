//
//  ManageTokensNetworkSelectorViewModelDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ManageTokensNetworkSelectorViewModelDelegate: AnyObject {
    func tokenItemsDidUpdate(by coinId: String)
}
