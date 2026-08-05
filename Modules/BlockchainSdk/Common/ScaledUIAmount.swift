//
//  ScaledUIAmount.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Conversions between the amounts shown to the user and the amounts the chain operates on for tokens
/// that declare a scaled UI amount configuration.
public enum ScaledUIAmount {
    public static func unscale(displayed amount: Decimal, by multiplier: Decimal?) throws -> Decimal {
        guard let multiplier else {
            return amount
        }

        guard multiplier > 0 else {
            throw BlockchainSdkError.failedToBuildTx
        }

        guard multiplier != 1 else {
            return amount
        }

        return amount / multiplier
    }

    public static func scale(onChain amount: Decimal, by multiplier: Decimal?) -> Decimal {
        guard let multiplier, multiplier > 0, multiplier != 1 else {
            return amount
        }

        return amount * multiplier
    }
}

/// Resolves a mint's multiplier once and hands the same answer to every later caller. A swap screen
/// quotes every provider in parallel and re-quotes on each keystroke, so resolving per caller would
/// mean a burst of identical requests.
public actor ScaledUIAmountMultiplierResolver {
    private let provider: any ScaledUIAmountProvider
    private let contractAddress: String
    private var resolutionTask: Task<Decimal?, Error>?

    public init(provider: any ScaledUIAmountProvider, contractAddress: String) {
        self.provider = provider
        self.contractAddress = contractAddress
    }

    public func resolve() async throws -> Decimal? {
        if let resolutionTask {
            return try await resolutionTask.value
        }

        let resolutionTask = Task {
            try await provider.fetchMultiplier(contractAddress: contractAddress)
        }

        self.resolutionTask = resolutionTask

        do {
            return try await resolutionTask.value
        } catch {
            // Errors are not retained, so a transient node failure can be retried by the next caller
            // instead of failing every quote for the rest of the flow.
            self.resolutionTask = nil
            throw error
        }
    }
}
