//
//  CardanoTransferRestrictable.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol CardanoTransferRestrictable {
    func validateCardanoTransfer(amount: Amount, fee: Fee) throws
}
