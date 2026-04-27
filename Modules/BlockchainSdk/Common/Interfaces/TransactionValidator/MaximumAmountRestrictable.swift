//
//  MaximumAmountRestrictable.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

protocol MaximumAmountRestrictable {
    func validateMaximumAmount(amount: Amount, fee: Amount) throws
}
