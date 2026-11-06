//
//  JointAccountKeyPath.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import struct TangemSdk.DerivationPath

enum JointAccountKeyPath {
    /// The address is a single EVM address for every supported network, so it is made for Ethereum.
    static let blockchain: Blockchain = .ethereum(testnet: false)

    /// `m/44'/60'/888888'/0/{index}`.
    /// - Warning: A part of the contract with the backend, which syncs the token list between the members by this path.
    static func derivationPath(forAccountAtIndex index: Int) throws -> DerivationPath {
        let accountIndex = try AccountDerivationIndex.nodeIndex(index)

        return DerivationPath(nodes: [
            .hardened(Constants.purposeNodeValue),
            .hardened(Constants.evmCoinTypeNodeValue),
            .hardened(Constants.jointAccountNodeValue),
            .nonHardened(0),
            .nonHardened(accountIndex),
        ])
    }

    static func blockchainNetwork(forAccountAtIndex index: Int) throws -> BlockchainNetwork {
        try BlockchainNetwork(blockchain, derivationPath: derivationPath(forAccountAtIndex: index))
    }
}

// MARK: - Constants

private extension JointAccountKeyPath {
    enum Constants {
        static let purposeNodeValue: UInt32 = 44
        static let evmCoinTypeNodeValue: UInt32 = 60
        static let jointAccountNodeValue: UInt32 = 888888
    }
}
