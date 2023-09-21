//
//  AddCustomTokenNetworkSelectorDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol AddCustomTokenNetworkSelectorDelegate: AnyObject {
    func didSelectNetwork(blockchain: Blockchain)
}
