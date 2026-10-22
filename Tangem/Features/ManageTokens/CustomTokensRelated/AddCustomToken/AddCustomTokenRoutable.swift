//
//  AddCustomTokenRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

protocol AddCustomTokenRoutable: AnyObject {
    func dismiss()
    func openNetworkSelector(selectedBlockchainNetworkId: String?, blockchains: [Blockchain])
    func openDerivationSelector(
        selectedDerivationOption: AddCustomTokenDerivationOption,
        defaultDerivationPath: DerivationPath,
        blockchainDerivationOptions: [AddCustomTokenDerivationOption],
        context: ManageTokensContext,
        blockchain: Blockchain
    )
}
