//
//  XRPInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct XRPInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard case .xrp = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let xrpNetworkService: XRPNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let response: XrpInfoResponse

        do {
            response = try await xrpNetworkService.getInfo(account: address).async()
        } catch {
            if case BlockchainSdkError.noAccount = error {
                return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: 0, tokens: [])
            }

            throw error
        }

        let nativeBalance = XRPAmountConverter(blockchain: blockchain).convertFromDrops(response.balance)

        guard case .success(let trustlines) = response.trustlines else {
            return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: nativeBalance, tokens: [])
        }

        let aggregatedBalances = trustlines
            .compactMap { trustline -> (contractAddress: String, balance: Decimal)? in
                guard
                    trustline.freezePeer != true,
                    let balance = Decimal(stringValue: trustline.balance)
                else {
                    return nil
                }

                return (contractAddress: makeAssetId(from: trustline), balance: balance)
            }
            .reduce(into: [String: Decimal]()) { result, trustline in
                result[trustline.contractAddress, default: 0] += trustline.balance
            }

        let tokenBalances = aggregatedBalances.map { contractAddress, balance in
            WalletAssetsDiscoveryTokenBalance(contractAddress: contractAddress, balance: balance)
        }

        return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: nativeBalance, tokens: tokenBalances)
    }

    private func makeAssetId(from trustline: XRPTrustLine) -> String {
        // Keep asset-id formatting aligned with XRPWalletManager/XRPAssetIdParser usage.
        XRPAssetIdParser().normalizeAssetId("\(trustline.currency)-\(trustline.account)")
    }
}
