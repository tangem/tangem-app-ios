//
//  EarnModelMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemAssets

// MARK: - EarnModelMapper

struct EarnModelMapper {
    private let iconBuilder = IconURLBuilder()
    private let percentFormatter = PercentFormatter()
    private let networkImageProvider = NetworkImageProvider()
    private let supportedBlockchainsByNetworkId = Dictionary(
        uniqueKeysWithValues: SupportedBlockchains.all.map { ($0.networkId, $0) }
    )

    // MARK: - Implementation

    func mapToEarnTokenModel(from response: EarnDTO.List.Item) -> EarnTokenModel {
        let rateValue = Decimal(stringValue: response.apy) ?? 0
        let rateType: RateType = response.rewardType.lowercased() == Constants.apy ? .apy : .apr
        let earnType: EarnType = response.type.lowercased() == Constants.staking ? .staking : .yieldMode
        let blockchain = supportedBlockchainsByNetworkId[response.networkId]
        let rateText = "\(rateType.rawValue) \(percentFormatter.format(rateValue, option: .staking))"
        let blockchainIconAsset = blockchain.map { networkImageProvider.provide(by: $0, filled: true) }

        // With fallback to network id
        let networkName = blockchain?.displayName ?? response.networkId.capitalized

        return EarnTokenModel(
            id: response.token.id,
            name: response.token.name,
            symbol: response.token.symbol,
            imageUrl: iconBuilder.tokenIconURL(id: response.token.id),
            networkId: response.networkId,
            networkName: networkName,
            blockchainIconAsset: blockchainIconAsset,
            contractAddress: response.token.address,
            decimalCount: response.token.decimalCount,
            rateValue: rateValue,
            rateType: rateType,
            rateText: rateText,
            earnType: earnType
        )
    }

    // Constants

    private enum Constants {
        static let apy = "apy"
        static let staking = "staking"
    }
}
