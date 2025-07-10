//
//  CardanoAssetFilter.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CardanoAssetFilter {
    private let contractAddress: String
    private let converter = CardanoTokenContractAddressService()

    init(contractAddress: String) {
        self.contractAddress = contractAddress
    }

    func isEqualToAssetWith(policyId: String, assetNameHex: String) -> Bool {
        let address = policyId + assetNameHex
        let assetFingerprint = try? converter.convertToFingerprint(address: address, symbol: nil)
        return contractAddress == assetFingerprint
    }
}
