//
//  SurveySparrowDTO+CheckExisting.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension SurveySparrowDTO.CheckExisting {
    struct Request: Encodable {
        let surveyId: Int
        let transactionId: String

        enum CodingKeys: String, CodingKey {
            case surveyId = "survey_id"
            case variables
            case limit
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(surveyId, forKey: .surveyId)
            try container.encode(1, forKey: .limit)

            // SurveySparrow API requires variables as JSON string in query params
            let variablesDict = ["tx_external_id": transactionId]
            let data = try JSONSerialization.data(withJSONObject: variablesDict)

            guard let jsonString = String(data: data, encoding: .utf8) else {
                let context = EncodingError.Context(
                    codingPath: [CodingKeys.variables],
                    debugDescription: "Failed to encode variables as UTF-8 string"
                )
                throw EncodingError.invalidValue(variablesDict, context)
            }

            try container.encode(jsonString, forKey: .variables)
        }
    }

    struct Response: Decodable {
        let data: [ResponseItem]

        struct ResponseItem: Decodable {
            let answers: [Answer]
        }

        struct Answer: Decodable {
            let questionId: Int?
            let answer: String?

            enum CodingKeys: String, CodingKey {
                case questionId = "question_id"
                case answer
            }

            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                // question_id can be Int (1328680) or String ("startTime") - we only care about Int
                questionId = try? container.decode(Int.self, forKey: .questionId)
                // answer can be Int, String, or missing
                answer = try? container.decodeStringOrInt(forKey: .answer)
            }
        }
    }
}

// MARK: - Private Helpers

private extension KeyedDecodingContainer {
    func decodeStringOrInt(forKey key: Key) throws -> String {
        if let string = try? decode(String.self, forKey: key) {
            return string
        }
        return String(try decode(Int.self, forKey: key))
    }
}
