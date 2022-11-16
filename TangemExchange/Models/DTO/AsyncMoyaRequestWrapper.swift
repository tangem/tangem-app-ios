//
//  AsyncMoyaRequestWrapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

class AsyncMoyaRequestWrapper<T: Decodable> {
    typealias MoyaContinuation = CheckedContinuation<Result<T, ExchangeInchError>, Never>

    var performRequest: (MoyaContinuation) -> Moya.Cancellable?
    var cancellable: Moya.Cancellable?

    init(_ performRequest: @escaping (MoyaContinuation) -> Moya.Cancellable?) {
        self.performRequest = performRequest
    }

    func perform(continuation: MoyaContinuation) {
        cancellable = performRequest(continuation)
    }

    func cancel() {
        cancellable?.cancel()
    }
}
