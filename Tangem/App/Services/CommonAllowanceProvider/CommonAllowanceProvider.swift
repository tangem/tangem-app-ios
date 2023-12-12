//
//  CommonAllowanceProvider.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping
import BlockchainSdk

class CommonExpressAllowanceProvider {
    private var ethereumNetworkProvider: EthereumNetworkProvider?
    private var ethereumTransactionProcessor: EthereumTransactionProcessor?
    private let logger: SwappingLogger

    private var spendersAwaitingApprove = Set<String>()

    init(logger: SwappingLogger) {
        self.logger = logger
    }
}

// MARK: - ExpressAllowanceProvider

extension CommonExpressAllowanceProvider: ExpressAllowanceProvider {
    func setup(wallet: WalletModel) {
        ethereumNetworkProvider = wallet.ethereumNetworkProvider
        ethereumTransactionProcessor = wallet.ethereumTransactionProcessor
    }

    func didSendApproveTransaction(for spender: String) {
        spendersAwaitingApprove.insert(spender)
    }

    func isPermissionRequired(request: ExpressManagerSwappingPairRequest, for spender: String) async throws -> Bool {
        let contractAddress = request.pair.source.expressCurrency.contractAddress

        if contractAddress == ExpressConstants.coinContractAddress {
            return false
        }

        assert(contractAddress != ExpressConstants.coinContractAddress)

        let allowanceWEI = try await getAllowance(
            owner: request.pair.source.defaultAddress,
            to: spender,
            contract: contractAddress
        )

        let allowance = request.pair.source.convertFromWEI(value: allowanceWEI)
        logger.debug("\(request.pair.source) allowance - \(allowance)")

        let approveTxWasSent = spendersAwaitingApprove.contains(spender)
        let hasEnoughAllowance = allowance >= request.amount
        if approveTxWasSent {
            if hasEnoughAllowance {
                spendersAwaitingApprove.remove(spender)
                return hasEnoughAllowance
            } else {
                throw AllowanceProviderError.approveTransactionInProgress
            }
        }
        return !hasEnoughAllowance
    }

    func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal {
        guard let ethereumNetworkProvider else {
            throw AllowanceProviderError.ethereumNetworkProviderNotFound
        }

        let allowance = try await ethereumNetworkProvider.getAllowance(
            owner: owner,
            spender: spender,
            contractAddress: contract
        ).async()

        return allowance
    }

    func makeApproveData(spender: String, amount: Decimal) throws -> Data {
        guard let ethereumTransactionProcessor else {
            throw AllowanceProviderError.ethereumTransactionProcessorNotFound
        }

        return ethereumTransactionProcessor.buildForApprove(spender: spender, amount: amount)
    }
}
