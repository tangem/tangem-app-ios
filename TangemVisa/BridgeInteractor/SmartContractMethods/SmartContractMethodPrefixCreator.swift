//
//  SmartContractMethodPrefixCreator.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift

struct SmartContractMethodPrefixCreator {
    func createPrefixForMethod(with name: String) -> String {
        String(name.sha3(.keccak256).prefix(8))
    }
}
