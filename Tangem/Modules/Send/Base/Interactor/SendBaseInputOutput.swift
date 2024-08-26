//
//  SendBaseInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendBaseInput: AnyObject {
    var isFeeIncluded: Bool { get }

    var actionInProcessing: AnyPublisher<Bool, Never> { get }
}

protocol SendBaseOutput: AnyObject {
    func performAction() async throws -> SendTransactionDispatcherResult
}
