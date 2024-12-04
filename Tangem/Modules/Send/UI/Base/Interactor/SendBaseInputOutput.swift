//
//  SendBaseInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendBaseInput: AnyObject {
    var actionInProcessing: AnyPublisher<Bool, Never> { get }
}

protocol SendBaseOutput: AnyObject {
    func performAction() async throws -> TransactionDispatcherResult
    func flowDidDisappear()
}

extension SendBaseOutput {
    func flowDidDisappear() {}
}
