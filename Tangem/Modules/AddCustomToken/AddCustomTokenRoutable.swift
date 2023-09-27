//
//  AddCustomTokenRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol AddCustomTokenRoutable: AnyObject {
    func dismiss()
    func openNetworkSelector(selectedBlockchainNetworkId: String?, blockchains: [Blockchain])
}
