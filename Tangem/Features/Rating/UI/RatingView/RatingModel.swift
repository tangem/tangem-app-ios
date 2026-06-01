//
//  RatingModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct RatingModel: Sendable {
    // MARK: - Properties

    private let ratingProvider: RatingProvider
    private let transaction: Transaction
    private let userWalletIdHash: String

    // MARK: - Init

    init(
        ratingProvider: RatingProvider,
        transaction: Transaction,
        userWalletIdHash: String
    ) {
        self.ratingProvider = ratingProvider
        self.transaction = transaction
        self.userWalletIdHash = userWalletIdHash
    }

    // MARK: - Public Methods

    /// Returns existing rating if already rated, nil otherwise
    func checkExisting() async throws -> Int? {
        try await ratingProvider.checkExisting(for: transaction.externalTxId)?.rating
    }

    func submit(_ rating: Rating, feedback: String?) async throws -> SubmitResult {
        let normalizedFeedback = normalizeFeedback(feedback)

        let existing = try await ratingProvider.checkExisting(for: transaction.externalTxId)
        if let existing {
            return .alreadyRated(existing.rating)
        }

        let request = RatingRequest(
            transactionId: transaction.externalTxId,
            rating: rating.rawValue,
            feedback: normalizedFeedback,
            provider: transaction.providerName,
            userWalletIdHash: userWalletIdHash,
            txUrl: transaction.txUrl
        )
        try await ratingProvider.submit(request: request)

        return .success
    }
}

private extension RatingModel {
    // MARK: - Private logic

    func normalizeFeedback(_ feedback: String?) -> String? {
        guard let feedback else { return nil }
        let trimmed = feedback.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Nested types

extension RatingModel {
    enum SubmitResult: Equatable, Sendable {
        case success
        case alreadyRated(Int)
    }
}
