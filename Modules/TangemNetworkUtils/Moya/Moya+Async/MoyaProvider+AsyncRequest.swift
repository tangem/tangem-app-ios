//
//  MoyaProvider+AsyncRequest.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation

public extension MoyaProvider {
    func asyncRequest(_ target: Target) async throws -> Response {
        let cancellableWrapper = ThreadSafeCancellableWrapper()

        return try await withTaskCancellationHandler { [weak self] in
            try await withCheckedThrowingContinuation { continuation in
                // This check is necessary in case this code runs after the task was
                // cancelled. In which case we want to bail right away.
                guard !_Concurrency.Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                self?.request(target) { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }.eraseToAnyCancellable().store(in: cancellableWrapper)
            }
        } onCancel: {
            cancellableWrapper.cancel()
        }
    }
}
