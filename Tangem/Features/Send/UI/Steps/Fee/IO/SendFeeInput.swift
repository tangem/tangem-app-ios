//
//  SendFeeInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct BlockchainSdk.Amount

protocol SendFeeInput: AnyObject {
    var selectedFee: TokenFee? { get }
    var selectedFeePublisher: AnyPublisher<TokenFee, Never> { get }
    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> { get }
}
