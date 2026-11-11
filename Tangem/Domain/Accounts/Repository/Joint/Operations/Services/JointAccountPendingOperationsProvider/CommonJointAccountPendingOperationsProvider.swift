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
    private let membersService: JointAccountMembersService
    private let statusProvider: any JointAccountStatusProvider

    private let cryptoAccountId: String
    private let walletBuilder = JointAccountWalletBuilder()
    private let verifier = JointOperationVerifier()
    private let feeBoundsProvider = JointOperationFeeBoundsProvider()

    private lazy var sharedPendingOperationsPublisher = makePendingOperationsPublisher()

    init(
        userWalletId: UserWalletId,
        derivationIdentity: CryptoAccountDerivationIdentity,
        pendingOperationsRepository: JointAccountPendingOperationsRepository,
        walletModelsManager: WalletModelsManager,
        membersService: JointAccountMembersService,
        statusProvider: any JointAccountStatusProvider
    ) {
        self.pendingOperationsRepository = pendingOperationsRepository
        self.walletModelsManager = walletModelsManager
        self.membersService = membersService
        self.statusProvider = statusProvider

        // [REDACTED_TODO_COMMENT]
        cryptoAccountId = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString

        _ = sharedPendingOperationsPublisher
    }

    private func makePendingOperationsPublisher() -> AnyPublisher<[JointAccountPendingOperation], Never> {
        makeInputsPublisher()
            .withWeakCaptureOf(self)
            .map { $0.pendingOperations(in: $1.0, walletModels: $1.1, members: $1.2) }
            .removeDuplicates()
            .share(replay: 1)
            .eraseToAnyPublisher()
    }

    private func makePendingOperationPublisher(id: String) -> AnyPublisher<JointAccountPendingOperation?, Never> {
        Publishers.CombineLatest4(
            pendingOperationsRepository.operationPublisher(id: id),
            walletModelsManager.walletModelsPublisher,
            membersService.slotsPublisher
                .map(\.members)
                .removeDuplicates(),
            statusProvider.statusPublisher
        )
        .map { [weak self] operation, walletModels, members, _ in
            operation.flatMap { operation in
                self?.mapToJointAccountPendingOperation(operation: operation, walletModels: walletModels, members: members)
            }
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    private func makeInputsPublisher() -> AnyPublisher<(JointAccountOperations?, [any WalletModel], [JointAccountMember], JointAccountStatus), Never> {
        let cryptoAccountId = cryptoAccountId

        return Publishers.CombineLatest4(
            pendingOperationsRepository.pendingOperationsPublisher.map { $0.first(by: cryptoAccountId) }.removeDuplicates(),
            walletModelsManager.walletModelsPublisher,
            membersService.slotsPublisher.map(\.members).removeDuplicates(),
            statusProvider.statusPublisher
        )
        .eraseToAnyPublisher()
    }

    private func pendingOperations(
        in record: JointAccountOperations?,
        walletModels: [any WalletModel],
        members: [JointAccountMember]
    ) -> [JointAccountPendingOperation] {
        let operations = record?.operations.filter(\.status.isInFlight) ?? []

        return operations.compactMap {
            mapToJointAccountPendingOperation(operation: $0, walletModels: walletModels, members: members)
        }
    }

    /// - Returns: `nil` for an operation that cannot be shown: one of a form this version cannot read, or one in a token
    /// this wallet has not added yet.
    private func mapToJointAccountPendingOperation(
        operation: JointAccountOperation,
        walletModels: [any WalletModel],
        members: [JointAccountMember]
    ) -> JointAccountPendingOperation? {
        try? makePendingOperation(from: operation, walletModels: walletModels, members: members)
    }

    private func makePendingOperation(
        from operation: JointAccountOperation,
        walletModels: [any WalletModel],
        members: [JointAccountMember]
    ) throws -> JointAccountPendingOperation {
        let innerCallType = try SafeInnerCallTypeParser.parse(operation.safeTransaction.innerCall)
        let walletModel = try walletModel(relatedTo: innerCallType, chainId: operation.chainId, among: walletModels)
        let wallet = try walletBuilder.build(walletModel: walletModel)
        try verify(operation: operation, in: wallet, members: members)
        let feeTokenItem = feeTokenItem(of: operation, through: walletModel, among: walletModels)
        let initiator = initiator(of: operation, wallet: wallet, members: members)

        return JointAccountPendingOperation(
            wallet: wallet,
            initiator: initiator,
            operation: operation,
            innerCallType: innerCallType,
            feeTokenItem: feeTokenItem,
            handleProvider: self
        )
    }

    private func verify(operation: JointAccountOperation, in wallet: JointAccountWallet, members: [JointAccountMember]) throws {
        guard case .active(let safeAddress) = wallet.account?.jointAccountStatusProvider.status else {
            throw JointOperationError.accountNotActive
        }

        try verifier.verify(
            operation: operation,
            safeAddress: safeAddress,
            memberAddresses: members.map(\.address),
            feeBounds: feeBoundsProvider.displayBounds(chainId: operation.chainId)
        )
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
            throw JointAccountPendingOperationsProviderError.walletNotFound
        }

        return walletModel
    }

    private func initiator(
        of operation: JointAccountOperation,
        wallet: JointAccountWallet,
        members: [JointAccountMember]
    ) -> JointAccountPendingOperation.Initiator {
        if (try? wallet.ownAddress())?.caseInsensitiveEquals(to: operation.initiator) == true {
            return .me
        }

        if let member = members.first(where: { $0.address.caseInsensitiveEquals(to: operation.initiator) }) {
            return .member(name: member.name)
        }

        return .unlisted(address: operation.initiator)
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
    func hasPendingOperations(chainId: Int) -> Bool {
        let operations = pendingOperationsRepository.pendingOperations.first(by: cryptoAccountId)?.operations ?? []
        return operations.contains { $0.chainId == chainId && $0.status.isInFlight }
    }

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        sharedPendingOperationsPublisher
    }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable? {
        pendingOperationsRepository.requestFrequentUpdates(operationId: operationId)
    }

    func pendingOperation(from operation: JointAccountOperation) async throws -> JointAccountPendingOperation {
        try await makePendingOperation(
            from: operation,
            walletModels: walletModelsManager.walletModels,
            members: membersService.slotsPublisher.async().members
        )
    }

    func loadOperation(id: String) async throws -> JointAccountPendingOperation {
        let operation = try await pendingOperationsRepository.loadOperation(id: id, forCryptoAccountId: cryptoAccountId)

        return try await pendingOperation(from: operation)
    }
}

// MARK: - JointAccountPendingOperationHandleProvider protocol conformance

extension CommonJointAccountPendingOperationsProvider: JointAccountPendingOperationHandleProvider {
    func makeHandle(for pendingOperation: JointAccountPendingOperation) -> JointAccountPendingOperationHandle {
        JointAccountPendingOperationHandle(
            id: pendingOperation.id,
            wallet: pendingOperation.wallet,
            pendingOperationPublisher: makePendingOperationPublisher(id: pendingOperation.id)
        )
    }
}
