//
//  StellarInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct StellarInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .stellar = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let stellarNetworkService: StellarNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)

        do {
            let response = try await stellarNetworkService.getInfo(accountId: address, isAsset: false).async()

            let assetBalancesCount = response.assetBalances.count
            let fullReserve = response.baseReserve * Decimal(assetBalancesCount + StellarWalletManager.Constants.baseEntryCount)
            let spendableNative = response.balance - fullReserve
            let nativeBalance = max(spendableNative, 0)

            let assetIdParser = StellarAssetIdParser()
            let balancesByAssetId = response.assetBalances
                .reduce(into: [String: Decimal]()) { result, asset in
                    let assetId = assetIdParser.normalizeAssetId("\(asset.code)-\(asset.issuer)")
                    result[assetId, default: 0] += asset.balance
                }

            let tokenBalances = balancesByAssetId.map { contractAddress, balance in
                InitialWalletTokenSyncTokenBalance(contractAddress: contractAddress, balance: balance)
            }

            return InitialWalletTokenSyncConfiguration(nativeBalance: nativeBalance, tokens: tokenBalances)
        } catch {
            if case BlockchainSdkError.noAccount = error {
                return InitialWalletTokenSyncConfiguration(nativeBalance: 0, tokens: [])
            }

            throw error
        }
    }
}
