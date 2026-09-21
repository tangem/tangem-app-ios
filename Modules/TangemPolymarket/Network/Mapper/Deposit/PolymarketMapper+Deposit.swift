//
//  PolymarketMapper+Deposit.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Supported assets

extension PolymarketMapper {
    func mapSupportedAssets(_ response: PolymarketDTO.SupportedAssetsResponse) -> [PolymarketSupportedAsset] {
        var assets: [PolymarketSupportedAsset] = []
        assets.reserveCapacity(response.supportedAssets.count)

        var chainsWithoutFamily = Set<String>()
        var assetsWithoutMinimum = Set<String>()

        for dto in response.supportedAssets {
            guard let family = PolymarketChainFamily(chainId: dto.chainId) else {
                chainsWithoutFamily.insert("\(dto.chainName) (\(dto.chainId))")
                continue
            }

            guard let minCheckoutUSD = dto.minCheckoutUsd else {
                assetsWithoutMinimum.insert("\(dto.token.symbol) on \(dto.chainName)")
                continue
            }

            assets.append(makeSupportedAsset(dto, family: family, minCheckoutUSD: minCheckoutUSD))
        }

        if !chainsWithoutFamily.isEmpty {
            PolymarketLogger.warning(
                "The bridge lists chains this build has no address family for, their assets are unavailable: "
                    + chainsWithoutFamily.sorted().joined(separator: ", ")
            )
        }

        if !assetsWithoutMinimum.isEmpty {
            PolymarketLogger.warning(
                "The bridge lists assets without a checkout minimum, they are unavailable: "
                    + assetsWithoutMinimum.sorted().joined(separator: ", ")
            )
        }

        return assets
    }
}

// MARK: - Funding addresses

extension PolymarketMapper {
    func mapBridgeAddresses(_ dto: PolymarketDTO.FundingAddressesResponse) -> PolymarketBridgeAddresses {
        let addresses = PolymarketChainFamily.allCases.reduce(into: [PolymarketChainFamily: String]()) { result, family in
            guard let address = address(for: family, in: dto), !address.isEmpty else { return }
            result[family] = address
        }

        return PolymarketBridgeAddresses(addresses: addresses)
    }
}

// MARK: - Private implementation

private extension PolymarketMapper {
    func makeSupportedAsset(
        _ dto: PolymarketDTO.SupportedAsset,
        family: PolymarketChainFamily,
        minCheckoutUSD: Decimal
    ) -> PolymarketSupportedAsset {
        PolymarketSupportedAsset(
            chainId: dto.chainId,
            chainName: dto.chainName,
            family: family,
            token: PolymarketSupportedAsset.Token(
                name: dto.token.name,
                symbol: dto.token.symbol,
                address: dto.token.address,
                decimalCount: dto.token.decimals
            ),
            minCheckoutUSD: minCheckoutUSD
        )
    }

    func address(for family: PolymarketChainFamily, in dto: PolymarketDTO.FundingAddressesResponse) -> String? {
        switch family {
        case .evm: dto.address.evm
        case .svm: dto.address.svm
        case .btc: dto.address.btc
        case .tron: dto.address.tron
        }
    }
}
