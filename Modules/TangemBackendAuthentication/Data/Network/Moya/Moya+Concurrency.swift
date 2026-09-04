//
//  Moya+Concurrency.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import class Combine.AnyCancellable
import Moya
private import class TangemFoundation.ThreadSafeCancellableWrapper

extension MoyaProvider {
    func request(_ target: Target) async throws(Moya.MoyaError) -> Moya.Response {
        let protectedCancellable = ThreadSafeCancellableWrapper()

        let result = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let moyaCancellable = request(target) { result in
                    continuation.resume(returning: result)
                }
                protectedCancellable.set(AnyCancellable(moyaCancellable.cancel))
            }
        } onCancel: {
            protectedCancellable.cancel()
        }

        return try result.get()
    }
}

// [REDACTED_USERNAME], both safe to be Sendable. Thread safe mutable state and all constants.

extension MoyaProvider: @retroactive @unchecked Sendable {}
extension Moya.Response: @retroactive @unchecked Sendable {}
