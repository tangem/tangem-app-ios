//
//  RatingProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol RatingProvider: Sendable {
    func checkExisting(for transactionId: String) async throws -> ExistingRating?
    func submit(request: RatingRequest) async throws
}

private struct RatingProviderKey: InjectionKey {
    static var currentValue: RatingProvider = {
        let keys = InjectedValues[\.keysManager].surveySparrow
        return SurveySparrowRatingProvider(keys: keys)
    }()
}

extension InjectedValues {
    var ratingProvider: RatingProvider {
        get { Self[RatingProviderKey.self] }
        set { Self[RatingProviderKey.self] = newValue }
    }
}
