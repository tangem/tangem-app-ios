//
//  PsbtFeeRateLimit.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The fee-rate cap applied when extracting a transaction from a PSBT.
public enum PsbtFeeRateLimit {
    /// BDK's built-in `AbsurdFeeRate` cap (~25k sat/vB); no fallback on top of it.
    case bdkDefault
    /// A chain-specific cap (satoshi per virtual byte) for chains whose normal network fees
    /// exceed BDK's built-in one. When the PSBT fee rate is within this limit, extraction falls
    /// back to a path that bypasses BDK's cap; above it the fee is treated as a drain attempt
    /// and rejected.
    case chainOverride(satPerVByte: UInt64)

    public init(blockchain: Blockchain) {
        switch blockchain {
        case .dogecoin:
            self = .chainOverride(satPerVByte: Constants.dogecoinMaxFeeRate)
        default:
            self = .bdkDefault
        }
    }
}

private extension PsbtFeeRateLimit {
    enum Constants {
        /// Dogecoin Core's `RECOMMENDED_MIN_TX_FEE = COIN / 100` is 1_000_000 sat/kvB
        /// (= 1000 sat/vB), and wallets/aggregators pay ~50–120x that in practice (~1 DOGE/kvB,
        /// worth cents) — already over BDK's ~25k sat/vB cap, which thus rejects every normal
        /// transaction. This limit allows up to 1000x the Core recommended minimum.
        /// https://github.com/dogecoin/dogecoin/blob/master/src/policy/policy.h
        static let dogecoinMaxFeeRate: UInt64 = 1_000_000
    }
}
