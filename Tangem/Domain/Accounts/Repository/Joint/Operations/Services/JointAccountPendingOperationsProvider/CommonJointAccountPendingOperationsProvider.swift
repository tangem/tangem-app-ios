//
//  CommonJointAccountPendingOperationsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import BlockchainSdk
import BigInt
import TangemFoundation

/// Reads the account's share out of what the repository keeps for every account of the wallet, and pairs each
/// operation with the account's wallet it is made through.
/// - Note: An operation of a form this version cannot read is left out, and so is one in a token this wallet has not
/// added yet — until it is, since another member may have added it; the wallets are followed for that reason.
final class CommonJointAccountPendingOperationsProvider {
    private let pendingOperationsRepository: JointAccountPendingOperationsRepository
    private let walletModelsManager: WalletModelsManager

    private let cryptoAccountId: String
    private let walletBuilder = JointAccountWalletBuilder()

    private lazy var sharedPendingOperationsPublisher = makePendingOperationsPublisher()

    init(
        userWalletId: UserWalletId,
        derivationIdentity: CryptoAccountDerivationIdentity,
        pendingOperationsRepository: JointAccountPendingOperationsRepository,
        walletModelsManager: WalletModelsManager
    ) {
        self.pendingOperationsRepository = pendingOperationsRepository
        self.walletModelsManager = walletModelsManager

        // [REDACTED_TODO_COMMENT]
        cryptoAccountId = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString

        _ = sharedPendingOperationsPublisher
    }

    private func makePendingOperationsPublisher() -> AnyPublisher<[JointAccountPendingOperation], Never> {
        let cryptoAccountId = cryptoAccountId

        return Publishers.CombineLatest(
            pendingOperationsRepository.operationsPublisher
                .map { $0.first(by: cryptoAccountId) }
                .removeDuplicates(),
            walletModelsManager.walletModelsPublisher
        )
        .withWeakCaptureOf(self)
        .map { $0.pendingOperations(in: $1.0, walletModels: $1.1) }
        .removeDuplicates()
        .share(replay: 1)
        .eraseToAnyPublisher()
    }

    private func pendingOperations(
        in record: StoredJointAccountPendingOperations?,
        walletModels: [any WalletModel]
    ) -> [JointAccountPendingOperation] {
        let operations = record?.operations.filter(\.status.isInFlight) ?? []

        return operations.compactMap {
            mapToJointAccountPendingOperation(operation: $0, walletModels: walletModels)
        }
    }

    /// - Returns: `nil` for an operation that cannot be shown: one of a form this version cannot read, or one in a token
    /// this wallet has not added yet.
    private func mapToJointAccountPendingOperation(
        operation: JointAccountOperation,
        walletModels: [any WalletModel]
    ) -> JointAccountPendingOperation? {
        do {
            let innerCallType = try SafeInnerCallTypeParser.parse(operation.safeTransaction.innerCall)
            let walletModel = try walletModel(relatedTo: innerCallType, chainId: operation.chainId, among: walletModels)
            let wallet = try walletBuilder.build(walletModel: walletModel)
            let feeTokenItem = feeTokenItem(of: operation, through: walletModel, among: walletModels)

            return JointAccountPendingOperation(
                wallet: wallet,
                operation: operation,
                operationPublisher: pendingOperationsRepository.operationPublisher(id: operation.id, in: cryptoAccountId),
                innerCallType: innerCallType,
                feeTokenItem: feeTokenItem
            )
        } catch {
            return nil
        }
    }

    /// The account's wallet of the token a transfer moves: the network's own for the coin, the one at the contract for a
    /// token.
    private func walletModel(
        relatedTo innerCallType: SafeInnerCallType,
        chainId: Int,
        among walletModels: [any WalletModel]
    ) throws -> any WalletModel {
        let walletModel: (any WalletModel)? = switch innerCallType {
        case .transfer(.coin):
            walletModels.first { $0.tokenItem.blockchain.chainId == chainId && $0.tokenItem.isBlockchain }
        case .transfer(.token(let contractAddress, _, _)):
            self.walletModel(contractAddress: contractAddress, chainId: chainId, among: walletModels)
        }

        guard let walletModel else {
            throw Error.walletNotFound
        }

        return walletModel
    }

    private func feeTokenItem(
        of operation: JointAccountOperation,
        through walletModel: any WalletModel,
        among walletModels: [any WalletModel]
    ) -> TokenItem? {
        let gasToken = operation.safeTransaction.gasToken

        if gasToken.caseInsensitiveEquals(to: SafeGasToken.coinGasTokenRawValue) {
            return .blockchain(walletModel.tokenItem.blockchainNetwork)
        }

        guard let feeWalletModel = self.walletModel(contractAddress: gasToken, chainId: operation.chainId, among: walletModels) else {
            JointAccountsLogger.info("The fee of an unfinished operation of a joint account is in a token not added here")
            return nil
        }

        return feeWalletModel.tokenItem
    }

    private func walletModel(
        contractAddress: String,
        chainId: Int,
        among walletModels: [any WalletModel]
    ) -> (any WalletModel)? {
        walletModels.first {
            $0.tokenItem.blockchain.chainId == chainId
                && $0.tokenItem.contractAddress?.caseInsensitiveEquals(to: contractAddress) == true
        }
    }
}

// MARK: - JointAccountPendingOperationsProvider protocol conformance

extension CommonJointAccountPendingOperationsProvider: JointAccountPendingOperationsProvider {
    var pendingOperations: [JointAccountPendingOperation] {
        pendingOperations(
            in: pendingOperationsRepository.operations.first(by: cryptoAccountId),
            walletModels: walletModelsManager.walletModels
        )
    }

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        sharedPendingOperationsPublisher
    }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable? {
        pendingOperationsRepository.requestFrequentUpdates(operationId: operationId)
    }
}

// MARK: - Auxiliary types

private extension CommonJointAccountPendingOperationsProvider {
    enum Error: Swift.Error {
        /// The account has no wallet of the token on this device — another member may have added it.
        case walletNotFound
    }
}
