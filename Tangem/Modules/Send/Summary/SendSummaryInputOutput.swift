//
//  SendSummaryInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendSummaryInput: AnyObject {
    var transactionPublisher: AnyPublisher<SendTransactionType?, Never> { get }
}

protocol SendSummaryOutput: AnyObject {}
