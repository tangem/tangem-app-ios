//
//  SurveySparrowKeys.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SurveySparrowKeys: Decodable {
    /// API base URL (without trailing slash)
    let domain: String

    /// Bearer token for API authentication (same approach as Android)
    let token: String

    /// Swap rating survey configuration. Nil if not configured or invalid.
    let swapRating: SwapRating?

    enum CodingKeys: String, CodingKey {
        case domain
        case apiKey
        case swapRating
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        domain = try container.decodeIfPresent(String.self, forKey: .domain) ?? "eu-api.surveysparrow.com"
        token = try container.decodeIfPresent(String.self, forKey: .apiKey) ?? ""
        swapRating = try? container.decodeIfPresent(SwapRating.self, forKey: .swapRating) ?? .default
    }
}

extension SurveySparrowKeys {
    var isSwapRatingConfigured: Bool {
        !token.isEmpty && swapRating != nil
    }
}

extension SurveySparrowKeys {
    // MARK: - Swap rating

    struct SwapRating: Decodable {
        let surveyId: Int
        let ratingQuestionId: Int
        let feedbackQuestionId: Int

        init(surveyId: Int, ratingQuestionId: Int, feedbackQuestionId: Int) {
            self.surveyId = surveyId
            self.ratingQuestionId = ratingQuestionId
            self.feedbackQuestionId = feedbackQuestionId
        }

        enum CodingKeys: String, CodingKey {
            case surveyId
            case ratingQuestionId
            case feedbackQuestionId
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            surveyId = try Self.decodeInt(from: container, forKey: .surveyId)
            ratingQuestionId = try Self.decodeInt(from: container, forKey: .ratingQuestionId)
            feedbackQuestionId = try Self.decodeInt(from: container, forKey: .feedbackQuestionId)
        }
    }
}

private extension SurveySparrowKeys.SwapRating {
    // MARK: - Private logic

    /// Defaults
    /// SurveySparrow IDs configured in the dashboard for the swap rating survey.
    static let `default` = SurveySparrowKeys.SwapRating(
        surveyId: 270_857,
        ratingQuestionId: 1_328_680,
        feedbackQuestionId: 1_337_594
    )

    static func decodeInt(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Int {
        let string = try container.decode(String.self, forKey: key)
        guard let value = Int(string) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "Expected a numeric string for \(key.stringValue), got '\(string)'"
            )
        }
        return value
    }
}
