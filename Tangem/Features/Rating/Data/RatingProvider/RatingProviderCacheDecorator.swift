//
//  RatingProviderCacheDecorator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct RatingProviderCacheDecorator: RatingProvider {
    private let decoratee: RatingProvider
    private let entries = OSAllocatedUnfairLock<[String: Entry]>(initialState: [:])

    init(decoratee: RatingProvider) {
        self.decoratee = decoratee
    }

    func checkExisting(for transactionId: String) async throws -> ExistingRating? {
        switch entry(for: transactionId) {
        case .known(let rating):
            return rating
        case .loading(let task):
            return try await task.value
        }
    }

    func submit(request: RatingRequest) async throws {
        do {
            try await decoratee.submit(request: request)
        } catch {
            entries { $0[request.transactionId] = nil }
            throw error
        }

        entries { $0[request.transactionId] = .known(ExistingRating(rating: request.rating, feedback: request.feedback)) }
    }
}

// MARK: - Private logic

private extension RatingProviderCacheDecorator {
    func entry(for transactionId: String) -> Entry {
        entries { entries in
            if let entry = entries[transactionId] {
                return entry
            }

            let entry = Entry.loading(Task { try await load(transactionId) })
            entries[transactionId] = entry
            return entry
        }
    }

    func load(_ transactionId: String) async throws -> ExistingRating? {
        do {
            let rating = try await decoratee.checkExisting(for: transactionId)
            entries { $0[transactionId] = .known(rating) }
            return rating
        } catch {
            entries { $0[transactionId] = nil }
            throw error
        }
    }
}

// MARK: - Nested types

private extension RatingProviderCacheDecorator {
    enum Entry {
        case loading(Task<ExistingRating?, Error>)
        case known(ExistingRating?)
    }
}
