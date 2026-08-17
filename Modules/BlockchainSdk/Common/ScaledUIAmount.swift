//
//  ScaledUIAmount.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Rules for the multiplier a Solana Token-2022 mint may declare to scale the amounts the app shows.
public enum ScaledUIAmount {
    /// How many providers have to report the same thing before it is allowed to rescale a transfer.
    public static let corroboratingProviderCount = 2

    /// What a provider reported about a mint's scaling.
    public enum Answer: Equatable {
        case multiplier(Decimal)
        case noScaling
        /// The response settled nothing about the mint, so the provider gets no say in the vote.
        case unknown
    }

    /// An answer that settles something and therefore takes part in the vote.
    public enum Vote: Equatable {
        case multiplier(Decimal)
        case noScaling

        public var multiplier: Decimal? {
            switch self {
            case .multiplier(let multiplier):
                return multiplier
            case .noScaling:
                return nil
            }
        }

        init?(_ answer: Answer) {
            switch answer {
            case .multiplier(let multiplier):
                self = .multiplier(multiplier)
            case .noScaling:
                self = .noScaling
            case .unknown:
                return nil
            }
        }
    }

    /// A node's answer carries no proof that it reflects the chain, and this multiplier divides the amount the card
    /// signs, so it is acted on only once `corroboratingProviderCount` providers have reported it identically.
    ///
    /// `noScaling` needs the same confirmation as a multiplier: reporting no scaling for a mint that declares one
    /// skips the division, which inflates the transfer just as an understated multiplier does. An `unknown` answer
    /// neither votes nor counts towards the quorum — a provider that cannot speak about the extension must not be
    /// able to block the transfer by contradicting one that can.
    /// - Parameter answers: What providers have reported so far, in the order they answered.
    /// - Returns: The confirmed value, or `nil` while nothing has gathered its confirmations — asking the providers
    ///   that have not answered yet can still settle it, which is why disagreement alone is not refused here.
    public static func corroborated(in answers: [Answer]) -> Vote? {
        let votes = answers.compactMap(Vote.init)

        return votes.first { candidate in
            votes.filter { $0 == candidate }.count >= corroboratingProviderCount
        }
    }

    /// The verdict once every provider has been heard.
    /// - Throws: `scaledUIAmountMultiplierMismatch` when enough providers settled something but never the same thing,
    ///   `scaledUIAmountMultiplierNotCorroborated` when too few of them settled anything at all.
    public static func corroborate(answers: [Answer]) throws -> Decimal? {
        if let corroborated = corroborated(in: answers) {
            return corroborated.multiplier
        }

        let voteCount = answers.compactMap(Vote.init).count

        throw voteCount >= corroboratingProviderCount
            ? BlockchainSdkError.scaledUIAmountMultiplierMismatch
            : BlockchainSdkError.scaledUIAmountMultiplierNotCorroborated
    }
}
