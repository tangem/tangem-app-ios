//
//  SurveySparrowDTOTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("SurveySparrowDTO")
final class SurveySparrowDTOTests {
    // MARK: - Empty Response

    @Test("Decodes empty data array")
    func decodesEmptyData() throws {
        let json = """
        {"data":[],"has_next_page":false,"total_count":0}
        """

        let dto = try decode(json)

        #expect(dto.data.isEmpty)
    }

    // MARK: - Question ID Handling

    @Test("Decodes numeric question_id as Int")
    func decodesNumericQuestionId() throws {
        let json = """
        {
            "data": [{
                "answers": [
                    {"question_id": 1328680, "answer": "4"}
                ]
            }]
        }
        """

        let dto = try decode(json)
        let answer = dto.data.first?.answers.first

        #expect(answer?.questionId == 1328680)
    }

    @Test("Decodes string question_id as nil")
    func decodesStringQuestionIdAsNil() throws {
        let json = """
        {
            "data": [{
                "answers": [
                    {"question_id": "startTime", "answer": "2026-05-21T05:16:56.787Z"}
                ]
            }]
        }
        """

        let dto = try decode(json)
        let answer = dto.data.first?.answers.first

        #expect(answer?.questionId == nil)
        #expect(answer?.answer == "2026-05-21T05:16:56.787Z")
    }

    @Test("Handles mixed question_id types in same response")
    func handlesMixedQuestionIdTypes() throws {
        let json = """
        {
            "data": [{
                "answers": [
                    {"question_id": 1328680, "answer": "4"},
                    {"question_id": "startTime", "answer": "2026-05-21"},
                    {"question_id": 1337594, "answer": "Great!"},
                    {"question_id": "totalScore"}
                ]
            }]
        }
        """

        let dto = try decode(json)
        let answers = dto.data.first?.answers ?? []

        #expect(answers.count == 4)

        // Numeric IDs are preserved
        #expect(answers[0].questionId == 1328680)
        #expect(answers[2].questionId == 1337594)

        // String IDs become nil
        #expect(answers[1].questionId == nil)
        #expect(answers[3].questionId == nil)
    }

    // MARK: - Answer Field Handling

    @Test("Decodes string answer")
    func decodesStringAnswer() throws {
        let json = """
        {
            "data": [{
                "answers": [
                    {"question_id": 1337594, "answer": "Great service!"}
                ]
            }]
        }
        """

        let dto = try decode(json)

        #expect(dto.data.first?.answers.first?.answer == "Great service!")
    }

    @Test("Decodes numeric answer as string")
    func decodesNumericAnswerAsString() throws {
        let json = """
        {
            "data": [{
                "answers": [
                    {"question_id": 1328680, "answer": 4}
                ]
            }]
        }
        """

        let dto = try decode(json)

        #expect(dto.data.first?.answers.first?.answer == "4")
    }

    @Test("Decodes missing answer as nil")
    func decodesMissingAnswerAsNil() throws {
        let json = """
        {
            "data": [{
                "answers": [
                    {"question_id": "totalScore"}
                ]
            }]
        }
        """

        let dto = try decode(json)

        #expect(dto.data.first?.answers.first?.answer == nil)
    }

    // MARK: - Real API Response

    @Test("Decodes real SurveySparrow API response")
    func decodesRealResponse() throws {
        let json = """
        {
            "data": [{
                "id": 18948846,
                "completed_time": "2026-05-21T05:16:56.940Z",
                "survey_id": 270857,
                "answers": [
                    {"answer": 4, "rating_scale": 5, "question": "Rate US", "question_id": 1328680, "skipped": false},
                    {"answer": "Great swap!", "question": "Opinion", "question_id": 1337594, "skipped": false},
                    {"answer": "2026-05-21T05:16:56.787Z", "question_id": "startTime"},
                    {"answer": "2026-05-21T05:16:56.940Z", "question_id": "submittedTime"},
                    {"answer": "null", "question_id": "ip"},
                    {"answer": "COMPUTER", "question_id": "deviceType"},
                    {"question_id": "totalScore"}
                ]
            }],
            "has_next_page": false,
            "total_count": 1
        }
        """

        let dto = try decode(json)

        #expect(dto.data.count == 1)

        let answers = dto.data.first?.answers ?? []
        #expect(answers.count == 7)

        // Find rating answer
        let ratingAnswer = answers.first { $0.questionId == 1328680 }
        #expect(ratingAnswer?.answer == "4")

        // Find feedback answer
        let feedbackAnswer = answers.first { $0.questionId == 1337594 }
        #expect(feedbackAnswer?.answer == "Great swap!")

        // Metadata answers have nil questionId
        let totalScoreAnswer = answers.last
        #expect(totalScoreAnswer?.questionId == nil)
        #expect(totalScoreAnswer?.answer == nil)
    }

    // MARK: - Edge Cases

    @Test("Decodes empty answers array")
    func decodesEmptyAnswers() throws {
        let json = """
        {
            "data": [{
                "answers": []
            }]
        }
        """

        let dto = try decode(json)

        #expect(dto.data.first?.answers.isEmpty == true)
    }

    @Test("Decodes feedback with newlines")
    func decodesFeedbackWithNewlines() throws {
        let json = """
        {
            "data": [{
                "answers": [
                    {"question_id": 1337594, "answer": "Line 1\\nLine 2\\nLine 3"}
                ]
            }]
        }
        """

        let dto = try decode(json)

        #expect(dto.data.first?.answers.first?.answer == "Line 1\nLine 2\nLine 3")
    }

    @Test("Decodes feedback with unicode")
    func decodesFeedbackWithUnicode() throws {
        let json = """
        {
            "data": [{
                "answers": [
                    {"question_id": 1337594, "answer": "Great! \\ud83d\\ude80\\ud83d\\udcb0"}
                ]
            }]
        }
        """

        let dto = try decode(json)

        #expect(dto.data.first?.answers.first?.answer?.contains("🚀") == true)
    }

    @Test("Decodes zero rating")
    func decodesZeroRating() throws {
        let json = """
        {
            "data": [{
                "answers": [
                    {"question_id": 1328680, "answer": 0}
                ]
            }]
        }
        """

        let dto = try decode(json)

        #expect(dto.data.first?.answers.first?.answer == "0")
    }
}

// MARK: - Helpers

private extension SurveySparrowDTOTests {
    func decode(_ json: String) throws -> SurveySparrowDTO.CheckExisting.Response {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(SurveySparrowDTO.CheckExisting.Response.self, from: data)
    }
}
