//
//  SuiNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import GRPC
import WalletCore

final class SuiNetworkService: MultiNetworkProvider {
    let providers: [SuiNetworkProvider]
    let blockchainName: String = Blockchain.sui(curve: .ed25519_slip0010, testnet: false).displayName
    var currentProviderIndex: Int

    init(providers: [SuiNetworkProvider]) {
        self.providers = providers
        currentProviderIndex = 0
    }

    func getCoins(address: String) -> AnyPublisher<[SuiGetCoins.Coin], Error> {
        return providerPublisher { provider in
            provider
                .getCoins(address: address)
        }
    }

    func getBalances(address: String) -> AnyPublisher<[SuiBalance], Error> {
        return providerPublisher { provider in
            provider
                .getBalances(address: address)
        }
    }

    func getServiceInfo() -> AnyPublisher<SuiServiceInfo, Error> {
        return providerPublisher { provider in
            provider
                .getServiceInfo()
        }
    }

    func getReferenceGasPrice() -> AnyPublisher<SuiReferenceGasPrice, Error> {
        return providerPublisher { provider in
            provider
                .getReferenceGasPrice()
        }
    }

    func dryTransaction(transaction raw: String) -> AnyPublisher<SuiInspectTransaction, Error> {
        return providerPublisher { provider in
            provider
                .dryRunTransaction(transaction: raw)
        }
    }

    func sendTransaction(transaction raw: String, signature: String) -> AnyPublisher<SuiExecuteTransaction, Error> {
        return providerPublisher { provider in
            provider
                .sendTransaction(transaction: raw, signature: signature)
        }
    }

    func shouldStopSwitching(error: Error) -> Bool {
        guard let status = error as? GRPCStatus else {
            return false
        }

        return !Self.providerFailureCodes.contains(status.code)
    }
}

// MARK: - Constants

private extension SuiNetworkService {
    static let providerFailureCodes: Set<GRPCStatus.Code> = [
        .cancelled,
        .unknown,
        .deadlineExceeded,
        .permissionDenied,
        .resourceExhausted,
        .unimplemented,
        .internalError,
        .unavailable,
        .unauthenticated,
    ]
}
