//
//  SendFeeInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct BlockchainSdk.Amount

protocol SendSummaryFeeInput: AnyObject {
    var summaryFee: LoadableTokenFee { get }
    var summaryFeePublisher: AnyPublisher<LoadableTokenFee, Never> { get }
    var summaryCanEditFeePublisher: AnyPublisher<Bool, Never> { get }
}
