//
//  CommonJointAccountOperationsService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

/// Settles what an operation is and whether it may be made, and signs it; sending it and keeping what comes back is
/// the repository's.
struct CommonJointAccountOperationsService {
    private let jointAccountsRepository: JointAccountsRepository
    private let signerFactory: TangemSignerFactory
    private let compositionVerifier: JointAccountCompositionVerifier

    init(
        jointAccountsRepository: JointAccountsRepository,
        signerFactory: TangemSignerFactory,
        compositionVerifier: JointAccountCompositionVerifier = JointAccountCompositionVerifier()
    ) {
        self.jointAccountsRepository = jointAccountsRepository
        self.signerFactory = signerFactory
        self.compositionVerifier = compositionVerifier
    }
}

// MARK: - JointAccountOperationsService protocol conformance

extension CommonJointAccountOperationsService: JointAccountOperationsService {
    var hasNFCInteraction: Bool {
        signerFactory.makeSigner().hasNFCInteraction
    }

    /// Every check comes before the signature, so that a member is not asked for one that would be turned away.
    func createOperation(transaction: BSDKTransaction, in wallet: JointAccountWallet) async throws -> JointAccountOperation {
        guard let feeParameters = transaction.fee.parameters as? SafeTransactionFeeParameters else {
            throw JointOperationError.missingFeeParameters
        }

        let chainId = try chainId(of: wallet)
        let account = try activeAccount(of: wallet)
        let safeOperationsService = try safeOperationsService(of: wallet)

        try await ensureNetworkIsFree(chainId: chainId, cryptoAccountId: account.cryptoAccountId)

        let state = try await safeOperationsService.getSafeState()
        let nonce = try nonce(from: state, quotedAsDeployed: feeParameters.isDeployed)
        try verify(state: state, account: account)

        let safeAddress = account.safeAddress
        let innerCall = try makeInnerCall(transaction: transaction, in: safeOperationsService, safeAddress: safeAddress)
        let safeTransaction = SafeTransaction(innerCall: innerCall, feeParameters: feeParameters, nonce: nonce)

        let hash = safeTransaction.signHash(chainId: chainId, safeAddress: safeAddress)
        let signature = try await sign(hash: hash, walletPublicKey: wallet.publicKey)

        let request = JointAccountOperationRequest(
            safeAddress: safeAddress,
            chainId: chainId,
            safeTransaction: safeTransaction,
            signature: signature
        )

        return try await jointAccountsRepository.createOperation(request, forCryptoAccountId: account.cryptoAccountId)
    }

    func signOperation(_ operation: JointAccountOperation, in wallet: JointAccountWallet) async throws {
        let account = try activeAccount(of: wallet)
        let safeOperationsService = try safeOperationsService(of: wallet)

        // Checked anew: nothing binds the Safe on chain to what it was when the operation was created
        let state = try await safeOperationsService.getSafeState()
        try verify(state: state, account: account)
        try ensureIsNext(operation, at: state)

        let hash = operation.safeTransaction.signHash(chainId: operation.chainId, safeAddress: account.safeAddress)
        let signature = try await sign(hash: hash, walletPublicKey: wallet.publicKey)

        try await jointAccountsRepository.signOperation(
            id: operation.id,
            safeTransaction: operation.safeTransaction,
            signature: signature,
            forCryptoAccountId: account.cryptoAccountId
        )
    }

    /// Neither signed nor given anything to send: cancelling and declining are one and the same call, and which of
    /// the two it is the endpoint works out from the wallet it was made for.
    func rejectOperation(_ operation: JointAccountOperation, in wallet: JointAccountWallet) async throws {
        let account = try activeAccount(of: wallet)

        try await jointAccountsRepository.rejectOperation(
            id: operation.id,
            forCryptoAccountId: account.cryptoAccountId
        )
    }
}

// MARK: - Private

private extension CommonJointAccountOperationsService {
    func chainId(of wallet: JointAccountWallet) throws -> Int {
        guard let chainId = wallet.tokenItem.blockchain.chainId else {
            throw JointOperationError.unsupportedNetwork
        }

        return chainId
    }

    func safeOperationsService(of wallet: JointAccountWallet) throws -> any SafeWalletManagerOperationsService {
        guard let safeOperationsService = wallet.safeWalletManagerOperationsService else {
            throw JointOperationError.walletUnavailable
        }

        return safeOperationsService
    }

    func activeAccount(of wallet: JointAccountWallet) throws -> ActiveAccount {
        guard let account = wallet.account else {
            throw JointOperationError.accountUnavailable
        }

        guard case .active(let safeAddress) = account.status else {
            throw JointOperationError.accountNotActive
        }

        let members = account.jointAccountMembersService.slots.members
        return ActiveAccount(
            cryptoAccountId: account.id.rawValue.hexString,
            safeAddress: safeAddress,
            memberAddresses: members.map(\.address),
            signersCount: account.policy.signersCount
        )
    }

    /// The backend refuses a second unfinished operation in a network as well; asking here spares the member a
    /// signature that would be turned away.
    /// - Note: Read off the store rather than off the list the screens are given, which leaves out an operation in a
    /// token this device has not added — an operation nobody here can show holds the network all the same.
    func ensureNetworkIsFree(chainId: Int, cryptoAccountId: String) async throws {
        let records = try await jointAccountsRepository.jointAccountsPendingOperationsPublisher.async()
        let operations = records.first(by: cryptoAccountId)?.operations ?? []
        let isBusy = operations.contains { $0.chainId == chainId && $0.status.isInFlight }

        guard !isBusy else {
            throw JointOperationError.networkBusy
        }
    }

    /// An operation the Safe has moved past can never be executed, so nobody is asked to sign for it.
    func ensureIsNext(_ operation: JointAccountOperation, at state: SafeContractState) throws {
        guard state.nonce == operation.safeTransaction.nonce else {
            throw JointOperationError.operationSuperseded
        }
    }

    /// A deployment that happened since the quote changes `baseGas`, so the fee has to be quoted again rather than
    /// signed as it is.
    func nonce(from state: SafeContractState, quotedAsDeployed: Bool) throws -> Int {
        guard state.isDeployed == quotedAsDeployed else {
            throw JointOperationError.safeStateChanged
        }

        return state.nonce
    }

    func verify(state: SafeContractState, account: ActiveAccount) throws {
        try compositionVerifier.verify(
            state: state,
            safeAddress: account.safeAddress,
            memberAddresses: account.memberAddresses,
            signersCount: account.signersCount
        )
    }

    func makeInnerCall(transaction: BSDKTransaction, in safeOperationsService: SafeWalletManagerOperationsService, safeAddress: String) throws -> SafeInnerCall {
        // Custom calldata would be dropped by the transfer built below, so it is refused rather than misrepresented
        guard (transaction.params as? EthereumTransactionParams)?.data == nil else {
            throw JointOperationError.unsupportedOperationForm
        }

        let innerCall = try safeOperationsService.makeSafeInnerTransferCall(
            amount: transaction.amount,
            destination: transaction.destinationAddress
        )

        guard !innerCall.to.caseInsensitiveEquals(to: safeAddress) else {
            throw JointOperationError.unsupportedOperationForm
        }

        return innerCall
    }

    /// - Returns: `r ‖ s ‖ v` with `v` of 27 or 28 — the form `checkSignatures` reads an owner's ECDSA signature in,
    /// and the one the endpoint recovers a member's address from.
    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) async throws -> Data {
        let signer = signerFactory.makeSigner()
        let signatureInfo = try await signer.sign(hash: hash, walletPublicKey: walletPublicKey).async()

        return try signatureInfo.unmarshal()
    }
}

// MARK: - Auxiliary types

private extension CommonJointAccountOperationsService {
    struct ActiveAccount {
        let cryptoAccountId: String
        let safeAddress: String
        let memberAddresses: [String]
        let signersCount: Int
    }
}
