//
//  RatingProviderSpy.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import Tangem

actor RatingProviderSpy: RatingProvider {
    private(set) var checkResult: Result<ExistingRating?, Swift.Error> = .success(nil)
    private(set) var submitResult: Result<Void, Swift.Error> = .success(())
    private(set) var checkCalls: [String] = []
    private(set) var submitCalls: [RatingRequest] = []

    // MARK: - Setters

    func setCheckResult(_ result: Result<ExistingRating?, Swift.Error>) {
        checkResult = result
    }

    func setSubmitResult(_ result: Result<Void, Swift.Error>) {
        submitResult = result
    }

    // MARK: - RatingProvider

    func checkExisting(for transactionId: String) async throws -> ExistingRating? {
        checkCalls.append(transactionId)
        return try checkResult.get()
    }

    func submit(request: RatingRequest) async throws {
        submitCalls.append(request)
        try submitResult.get()
    }
}
