//
//  SurveyResponsesDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum SurveyResponsesDTO {}

// MARK: - Submit

extension SurveyResponsesDTO {
    enum Submit {
        struct Request: Encodable, Equatable {
            let surveyId: String
            let walletId: String
            let answers: [Answer]
        }

        struct Answer: Encodable, Equatable {
            let question: String
            let answer: String
        }
    }
}

// MARK: - Status

extension SurveyResponsesDTO {
    enum Status {
        struct Request: Equatable {
            let surveyId: String
            let walletId: String
        }

        struct Response: Decodable {
            let completed: Bool
        }
    }
}
