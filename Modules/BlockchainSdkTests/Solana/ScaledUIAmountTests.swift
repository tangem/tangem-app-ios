//
//  ScaledUIAmountTests.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import BlockchainSdk

/// Understating the multiplier inflates the amount the card signs: 10 tokens approved on screen become 10 000 in the
/// signed transfer.
private let understated = Decimal(stringValue: "0.001")!

struct ScaledUIAmountTests {
    @Test
    func agreeingProvidersCorroborateMultiplier() throws {
        #expect(try ScaledUIAmount.corroborate(answers: [.multiplier(2), .multiplier(2)]) == 2)
        #expect(try ScaledUIAmount.corroborate(answers: [.noScaling, .noScaling]) == nil)
    }

    /// A second provider reporting the true value stops the understated one, once every provider has been heard.
    @Test(arguments: [
        [ScaledUIAmount.Answer.multiplier(understated), .multiplier(1)],
        [.noScaling, .multiplier(understated)],
        [.multiplier(2), .noScaling],
    ])
    func disagreeingProvidersAreRejected(answers: [ScaledUIAmount.Answer]) {
        let thrown = #expect(throws: BlockchainSdkError.self) {
            try ScaledUIAmount.corroborate(answers: answers)
        }

        #expect(thrown?.isMultiplierMismatch == true)
    }

    /// `noScaling` is refused on its own as well: a mint that really declares a multiplier would have its division
    /// skipped, which inflates the transfer the same way an understated multiplier does.
    @Test(arguments: [ScaledUIAmount.Answer.noScaling, .multiplier(understated), .multiplier(1), .multiplier(2)])
    func singleAnswerIsRejected(answer: ScaledUIAmount.Answer) {
        let thrown = #expect(throws: BlockchainSdkError.self) {
            try ScaledUIAmount.corroborate(answers: [answer])
        }

        #expect(thrown?.isMultiplierNotCorroborated == true)
    }

    @Test
    func absentAnswersAreRejected() {
        let thrown = #expect(throws: BlockchainSdkError.self) {
            try ScaledUIAmount.corroborate(answers: [])
        }

        #expect(thrown?.isMultiplierNotCorroborated == true)
    }

    /// A provider that cannot speak about the extension must not be able to deny the transfer by contradicting one
    /// that can — otherwise a single lagging node in the list blocks every scaled mint for everyone.
    @Test
    func unknownAnswersDoNotVote() throws {
        #expect(try ScaledUIAmount.corroborate(answers: [.unknown, .multiplier(2), .multiplier(2)]) == 2)
        #expect(try ScaledUIAmount.corroborate(answers: [.noScaling, .unknown, .noScaling]) == nil)
    }

    /// Not voting also means not counting: an unknown answer cannot make up the pair.
    @Test(arguments: [
        [ScaledUIAmount.Answer.multiplier(2), .unknown],
        [.unknown, .noScaling],
        [.unknown, .unknown],
    ])
    func unknownAnswersDoNotCorroborate(answers: [ScaledUIAmount.Answer]) {
        let thrown = #expect(throws: BlockchainSdkError.self) {
            try ScaledUIAmount.corroborate(answers: answers)
        }

        #expect(thrown?.isMultiplierNotCorroborated == true)
    }

    /// While providers are still being polled, disagreement is not a refusal — the next answer can still confirm one
    /// of the values. Refusing at the first disagreement would let a single hostile node deny every transfer.
    @Test(arguments: [
        [],
        [ScaledUIAmount.Answer.multiplier(2)],
        [.multiplier(2), .noScaling],
        [.multiplier(2), .noScaling, .unknown],
        [.multiplier(2), .noScaling, .multiplier(understated)],
    ])
    func nothingIsCorroboratedUntilTwoVotesMatch(answers: [ScaledUIAmount.Answer]) {
        #expect(ScaledUIAmount.corroborated(in: answers) == nil)
    }

    @Test
    func aLateVoteBreaksTheTie() throws {
        #expect(ScaledUIAmount.corroborated(in: [.multiplier(2), .noScaling, .multiplier(2)]) == .multiplier(2))
        #expect(ScaledUIAmount.corroborated(in: [.multiplier(2), .unknown, .noScaling, .noScaling]) == .noScaling)

        #expect(try ScaledUIAmount.corroborate(answers: [.multiplier(2), .noScaling, .multiplier(2)]) == 2)
        #expect(try ScaledUIAmount.corroborate(answers: [.multiplier(2), .unknown, .noScaling, .noScaling]) == nil)
    }

    /// The rule is two matching answers, not the value with the most votes.
    @Test(arguments: [
        [ScaledUIAmount.Answer.multiplier(2), .noScaling, .multiplier(1)],
        [.multiplier(understated), .multiplier(1), .noScaling, .unknown],
    ])
    func pluralityIsNotEnough(answers: [ScaledUIAmount.Answer]) {
        #expect(ScaledUIAmount.corroborated(in: answers) == nil)

        let thrown = #expect(throws: BlockchainSdkError.self) {
            try ScaledUIAmount.corroborate(answers: answers)
        }

        #expect(thrown?.isMultiplierMismatch == true)
    }
}

private extension BlockchainSdkError {
    var isMultiplierMismatch: Bool {
        if case .scaledUIAmountMultiplierMismatch = self {
            return true
        }

        return false
    }

    var isMultiplierNotCorroborated: Bool {
        if case .scaledUIAmountMultiplierNotCorroborated = self {
            return true
        }

        return false
    }
}
