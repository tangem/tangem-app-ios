//
//  MoyaProvider+AsyncRequest.swift
//  TangemNetworkLayerAdditions
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public extension MoyaProvider {
    func asyncRequest(_ target: Target) async throws -> Response {
        let asyncRequestWrapper = AsyncMoyaRequestWrapper<Response> { [weak self] continuation in
            return self?.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                asyncRequestWrapper.perform(continuation: continuation)
            }
        } onCancel: {
            asyncRequestWrapper.cancel()
        }
    }
}

private class AsyncMoyaRequestWrapper<T> {
    typealias MoyaContinuation = CheckedContinuation<T, Error>

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
