//
//  GaslessExecutorVersion.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Deployment generation of the `Tangem7702GaslessExecutor` contract the account delegates to via EIP-7702.
///
/// The generations are not signature-compatible: a new one changes the EIP-712 `Transaction` struct. The
/// executor address and the signed payload therefore have to come from the same case, otherwise the executor
/// recovers a different signer and rejects the transaction.
public enum GaslessExecutorVersion {
    /// Batch execution, signing `Transaction(address to,uint256 value,uint256 gasLimit,bytes data)`.
    case batchCapable

    /// Whether the signed `Transaction` struct carries the gas forwarded to the user's call.
    public var requiresCallGasLimit: Bool {
        switch self {
        case .batchCapable: true
        }
    }
}
