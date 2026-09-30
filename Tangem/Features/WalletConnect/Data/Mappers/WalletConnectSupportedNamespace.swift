//
//  WalletConnectSupportedNamespace.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// CAIP namespaces https://namespaces.chainagnostic.org
enum WalletConnectSupportedNamespace: String {
    case eip155
    case solana
    /// Bitcoin namespace
    case bip122
    /// Hedera namespace (HIP-820), https://docs.reown.com/advanced/multichain/rpc-reference/hedera-rpc
    case hedera
}
