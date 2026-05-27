//
//  SurveySparrowRatingProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
@preconcurrency import TangemNetworkUtils

final class SurveySparrowRatingProvider: RatingProvider {
    // MARK: - Type Aliases

    typealias CheckExistingRequest = SurveySparrowDTO.CheckExisting.Request
    typealias CheckExistingResponse = SurveySparrowDTO.CheckExisting.Response
    typealias SubmitRequest = SurveySparrowDTO.Submit.Request

    // MARK: - Properties

    private let provider: TangemProvider<SurveySparrowTarget>
    private let keys: SurveySparrowKeys

    // MARK: - Init

    init(keys: SurveySparrowKeys) {
        self.keys = keys
        provider = TangemProvider<SurveySparrowTarget>(
            plugins: [Plugin(token: keys.token)]
        )
    }

    // MARK: - Public methods

    func checkExisting(for transactionId: String) async throws -> ExistingRating? {
        guard let rating = keys.swapRating else { return nil }
        guard let url = Self.makeURL(domain: keys.domain) else {
            throw Error.invalidURL
        }

        let response = try await fetchCheckExistingResponse(
            transactionId: transactionId,
            surveyId: rating.surveyId,
            baseURL: url
        )

        return rating.mapToExisting(with: response)
    }

    func submit(request: RatingRequest) async throws {
        guard let rating = keys.swapRating else { return }
        guard let url = Self.makeURL(domain: keys.domain) else {
            throw Error.invalidURL
        }

        let request = SubmitRequest(request: request, rating: rating)
        let target = SurveySparrowTarget(type: .submit(request: request), baseURL: url)

        _ = try await performRequest(target: target)
    }
}

private extension SurveySparrowRatingProvider {
    // MARK: - Check Existing

    func fetchCheckExistingResponse(
        transactionId: String,
        surveyId: Int,
        baseURL: URL
    ) async throws -> CheckExistingResponse {
        let request = CheckExistingRequest(surveyId: surveyId, transactionId: transactionId)
        let target = SurveySparrowTarget(type: .checkExisting(request: request), baseURL: baseURL)

        let data = try await performRequest(target: target)
        return try JSONDecoder().decode(CheckExistingResponse.self, from: data)
    }

    // MARK: - URL

    static func makeURL(domain: String) -> URL? {
        URL(string: "https://\(domain)")
    }

    // MARK: - Network

    func performRequest(target: SurveySparrowTarget) async throws -> Data {
        do {
            var response = try await provider.requestPublisher(target).async()
            response = try response.filterSuccessfulStatusAndRedirectCodes()
            return response.data
        } catch let moyaError as MoyaError {
            throw mapMoyaError(moyaError)
        } catch {
            throw Error.unknown
        }
    }

    func mapMoyaError(_ error: MoyaError) -> Error {
        switch error {
        case .underlying(let nsError as NSError, _) where nsError.domain == NSURLErrorDomain:
            return .networkError(URLError(URLError.Code(rawValue: nsError.code)))
        case .statusCode(let response):
            return .httpError(response.statusCode)
        default:
            return .decodingError
        }
    }
}

// MARK: - Nested types

extension SurveySparrowRatingProvider {
    enum Error: Swift.Error {
        case invalidURL
        case networkError(URLError)
        case httpError(Int)
        case decodingError
        case unknown
    }
}

// MARK: - Private Helpers

private extension SurveySparrowRatingProvider.CheckExistingResponse.ResponseItem {
    func answer(for questionId: Int) -> String? {
        answers.first { $0.questionId == questionId }?.answer
    }
}

private extension SurveySparrowRatingProvider.SubmitRequest {
    init(request: RatingRequest, rating: SurveySparrowKeys.SwapRating) {
        self.init(
            surveyId: rating.surveyId,
            ratingQuestionId: rating.ratingQuestionId,
            feedbackQuestionId: rating.feedbackQuestionId,
            rating: request.rating,
            feedback: request.feedback,
            transactionId: request.transactionId,
            providerName: request.provider,
            userWalletIdHash: request.userWalletIdHash,
            txUrl: request.txUrl
        )
    }
}

private extension SurveySparrowKeys.SwapRating {
    func mapToExisting(with response: SurveySparrowRatingProvider.CheckExistingResponse) -> ExistingRating? {
        guard let firstResponse = response.data.first else {
            return nil
        }

        guard let ratingValue = RatingModel.Rating(firstResponse.answer(for: ratingQuestionId)) else {
            return nil
        }

        let feedback = firstResponse.answer(for: feedbackQuestionId)
        return ExistingRating(rating: ratingValue.rawValue, feedback: feedback)
    }
}
