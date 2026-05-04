//
//  AddCustomTokenDerivationPathSelectorRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol AddCustomTokenDerivationPathSelectorRoutable: AnyObject {
    func didSelectOption(_ derivationOption: AddCustomTokenDerivationOption)
    func openDerivationPathWriter(
        currentDerivationPath: String,
        context: ManageTokensContext,
        blockchain: Blockchain,
        output: AddCustomTokenDerivationPathWriterOutput
    )
}
