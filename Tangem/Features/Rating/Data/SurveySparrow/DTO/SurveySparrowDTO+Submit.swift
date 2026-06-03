//
//  SurveySparrowDTO+Submit.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension SurveySparrowDTO.Submit {
    struct Request: Encodable {
        let surveyId: Int
        let ratingQuestionId: Int
        let feedbackQuestionId: Int
        let rating: Int
        let feedback: String?
        let transactionId: String
        let providerName: String
        let userWalletIdHash: String
        let txUrl: String?

        enum CodingKeys: String, CodingKey {
            case surveyId = "survey_id"
            case answers
            case variables
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(surveyId, forKey: .surveyId)

            // Build answers array
            var answers: [Answer] = [
                Answer(questionId: ratingQuestionId, answer: "\(rating)"),
            ]
            if let feedback, !feedback.isEmpty {
                answers.append(Answer(questionId: feedbackQuestionId, answer: feedback))
            }
            try container.encode(answers, forKey: .answers)

            // Build variables
            let variables = Variables(
                txExternalId: transactionId,
                providerName: providerName,
                userWalletIdHash: userWalletIdHash,
                txUrl: txUrl
            )
            try container.encode(variables, forKey: .variables)
        }
    }
}

// MARK: - Nested Types

extension SurveySparrowDTO.Submit.Request {
    struct Answer: Encodable {
        let questionId: Int
        let answer: String

        enum CodingKeys: String, CodingKey {
            case questionId = "question_id"
            case answer
        }
    }

    struct Variables: Encodable {
        let txExternalId: String
        let providerName: String
        let userWalletIdHash: String
        let txUrl: String?

        enum CodingKeys: String, CodingKey {
            case txExternalId = "tx_external_id"
            case providerName = "provider_name"
            case userWalletIdHash = "user_wallet_id"
            case txUrl = "tx_url"
        }
    }
}
