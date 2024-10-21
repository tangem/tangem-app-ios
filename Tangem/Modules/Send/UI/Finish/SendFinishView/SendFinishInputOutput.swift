//
//  SendFinishInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendFinishInput: AnyObject {
    var transactionSentDate: AnyPublisher<Date, Never> { get }
}
