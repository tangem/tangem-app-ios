//
//  CardActivationOrderProvider.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol CardActivationOrderProvider: AnyObject {
    func provideActivationOrderForSign() async throws -> CardActivationOrder
    func cancelOrderLoading()
}

struct CardActivationOrder {
    let activationOrder: String
    let dataToSign: Data
}

final class CommonCardActivationOrderProvider {
    private let accessTokenProvider: AuthorizationTokenHandler
    private let customerInfoService: CustomerInfoService
    private let logger: InternalLogger

    private var orderLoadingTask: Task<Void, Error>?

    init(
        accessTokenProvider: AuthorizationTokenHandler,
        customerInfoService: CustomerInfoService,
        logger: InternalLogger
    ) {
        self.accessTokenProvider = accessTokenProvider
        self.customerInfoService = customerInfoService
        self.logger = logger
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .cardActivationOrderProvider, message())
    }
}

extension CommonCardActivationOrderProvider: CardActivationOrderProvider {
    func provideActivationOrderForSign() async throws -> CardActivationOrder {
        // [REDACTED_TODO_COMMENT]
        try await Task.sleep(seconds: 5)
        let random = Int.random(in: 1 ... 2)
        if random % 2 == 0 {
            throw "Not implemented"
        } else {
            return .init(activationOrder: "Activation order to sign", dataToSign: Data())
        }
    }

    func provideActivationOrderForSign(completion: @escaping (Result<CardActivationOrder, any Error>) -> Void) {
        // [REDACTED_TODO_COMMENT]
        if let orderLoadingTask {
            orderLoadingTask.cancel()
            self.orderLoadingTask = nil
        }

        orderLoadingTask = Task { [weak self] in
            guard let self else { return }

            do {
                let order = try await provideActivationOrderForSign()
                completion(.success(order))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func cancelOrderLoading() {
        // [REDACTED_TODO_COMMENT]
        orderLoadingTask?.cancel()
    }
}
