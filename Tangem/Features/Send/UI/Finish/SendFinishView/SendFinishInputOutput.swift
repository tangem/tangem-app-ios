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
    var transactionURL: AnyPublisher<URL?, Never> { get }
}

extension SendFinishInput {
    var transactionURL: AnyPublisher<URL?, Never> { .just(output: nil) }
}
