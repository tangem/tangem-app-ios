//
//  AddCustomTokenNetworkSelectorCoordinatorOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol AddCustomTokenNetworkSelectorCoordinatorOutput: AnyObject {
    func didSelectNetwork(blockchain: Blockchain)
}
