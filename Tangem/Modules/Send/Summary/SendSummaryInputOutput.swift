//
//  SendSummaryInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct BlockchainSdk.Transaction

protocol SendSummaryInput: AnyObject {
    var transactionPublisher: AnyPublisher<BlockchainSdk.Transaction?, Never> { get }
}

protocol SendSummaryOutput: AnyObject {}
