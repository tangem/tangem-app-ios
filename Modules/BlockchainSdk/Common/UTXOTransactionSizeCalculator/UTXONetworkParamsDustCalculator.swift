//
//  UTXONetworkParamsDustCalculator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UTXONetworkParamsDustCalculator {
    func dust(outputSize: Int, type: UTXOScriptType) -> Int
}

// MARK: - Bitcoin-family (script-aware, fee-rate-based)

/// Bitcoin Core's GetDustThreshold approximation:
/// https://github.com/bitcoin/bitcoin/blob/dfb7d58108daf3728f69292b9e6dba437bb79cc7/src/policy/policy.cpp#L26
///
/// Per-network values live in `UTXONetworkParamsDustCalculator+Networks.swift`.
struct BitcoinUTXONetworkParamsDustCalculator: UTXONetworkParamsDustCalculator {
    let dustRelayTxFee: Int

    func dust(outputSize: Int, type: UTXOScriptType) -> Int {
        let threshold = outputSize * dustRelayTxFee / 1000
        return type.isWitness ? max(threshold, 294) : max(threshold, 546)
    }
}

// MARK: - Dogecoin (fixed hard dust limit)

/// Dogecoin Core enforces a fixed hard dust limit in IsStandardTx, independent of
/// the Bitcoin-style `(outputSize + inputSize) * dustRelayFee / 1000` formula.
///
/// Source references (pinned to commit 699f62c on master):
/// - DEFAULT_HARD_DUST_LIMIT = DEFAULT_DUST_LIMIT / 10
///   https://github.com/dogecoin/dogecoin/blob/699f62ccba4e9c886a44d578c3923b4e14ef0a08/src/policy/policy.h#L81
/// - DEFAULT_DUST_LIMIT = RECOMMENDED_MIN_TX_FEE = COIN / 100
///   https://github.com/dogecoin/dogecoin/blob/699f62ccba4e9c886a44d578c3923b4e14ef0a08/src/policy/policy.h#L70
///   https://github.com/dogecoin/dogecoin/blob/699f62ccba4e9c886a44d578c3923b4e14ef0a08/src/policy/policy.h#L23
/// - COIN = 100_000_000
///   https://github.com/dogecoin/dogecoin/blob/699f62ccba4e9c886a44d578c3923b4e14ef0a08/src/amount.h#L18
/// - Applied in IsStandardTx via txout.IsDust(nHardDustLimit)
///   https://github.com/dogecoin/dogecoin/blob/699f62ccba4e9c886a44d578c3923b4e14ef0a08/src/policy/policy.cpp#L109
///
/// Final value: (100_000_000 / 100) / 10 = 100_000 satoshi.
struct DogecoinUTXONetworkParamsDustCalculator: UTXONetworkParamsDustCalculator {
    func dust(outputSize: Int, type: UTXOScriptType) -> Int {
        100_000
    }
}

// MARK: - Pepecoin (Dogecoin Core fork — same hard dust limit)

/// Pepecoin Core is a Dogecoin Core fork and inherits its policy verbatim,
/// including the fixed `nHardDustLimit` rejected by `IsStandardTx`.
///
/// Source references (pinned to master at the time of writing):
/// - DEFAULT_HARD_DUST_LIMIT = DEFAULT_DUST_LIMIT / 10
///   https://github.com/pepecoinppc/pepecoin/blob/master/src/policy/policy.h#L81
/// - DEFAULT_DUST_LIMIT = RECOMMENDED_MIN_TX_FEE = COIN / 100
///   https://github.com/pepecoinppc/pepecoin/blob/master/src/policy/policy.h#L70
///   https://github.com/pepecoinppc/pepecoin/blob/master/src/policy/policy.h#L23
/// - Applied in IsStandardTx via txout.IsDust(nHardDustLimit)
///   https://github.com/pepecoinppc/pepecoin/blob/master/src/policy/policy.cpp#L109
///
/// Final value: (100_000_000 / 100) / 10 = 100_000 satoshi.
struct PepecoinUTXONetworkParamsDustCalculator: UTXONetworkParamsDustCalculator {
    func dust(outputSize: Int, type: UTXOScriptType) -> Int {
        100_000
    }
}

// MARK: - Kaspa (fixed dust limit)

/// Kaspa uses a fixed dust limit independent of script type and fee rate.
/// https://kaspa-mdbook.aspectron.com/transactions/constraints/dust.html
struct KaspaUTXONetworkParamsDustCalculator: UTXONetworkParamsDustCalculator {
    func dust(outputSize: Int, type: UTXOScriptType) -> Int {
        KaspaTransactionBuilder.dustValue
    }
}
