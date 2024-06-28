//
//  SendAmountInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendAmountInput: AnyObject {
    var amount: SendAmount? { get }
}

protocol SendAmountOutput: AnyObject {
    func amountDidChanged(amount: SendAmount?)
}
