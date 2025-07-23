//
//  WCHandlersService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit
import BlockchainSdk

protocol WCHandlersService {
    func validate(_ request: Request) async throws -> WCValidatedRequest

    func makeHandleTransactionDTO(
        from validatedRequest: WCValidatedRequest,
        connectedBlockchains: [BlockchainSdk.Blockchain]
    ) async throws -> WCHandleTransactionDTO
}

final class CommonWCHandlersService {
    // MARK: - Dependencies

    @Injected(\.connectedDAppRepository) private var connectedDAppRepository: any WalletConnectConnectedDAppRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let wcHandlersFactory: WalletConnectHandlersCreator

    init(wcHandlersFactory: WalletConnectHandlersCreator) {
        self.wcHandlersFactory = wcHandlersFactory
    }

    private func getHandler(
        for request: Request,
        blockchainId: String,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) async throws -> WalletConnectMessageHandler {
        let method = request.method

        guard let wcAction = WalletConnectMethod(rawValue: method) else {
            throw WalletConnectV2Error.unsupportedWCMethod(method)
        }

        return try wcHandlersFactory.createHandler(
            for: wcAction,
            with: request.params,
            blockchainId: blockchainId,
            signer: signer,
            walletModelProvider: walletModelProvider
        )
    }
}

// MARK: - WCHandlersService

extension CommonWCHandlersService: WCHandlersService {
    /// Validate the request and return a validated request object
    func validate(_ request: Request) async throws -> WCValidatedRequest {
        let logSuffix = " for request: \(request.id)"

        // Session validation
        guard let connectedDApp = try? await connectedDAppRepository.getDApp(with: request.topic) else {
            WCLogger.warning("Failed to find session in storage \(logSuffix)")
            throw WalletConnectV2Error.wrongCardSelected
        }

        // Blockchain validation
        guard let targetBlockchain = WCUtils.makeBlockchainMeta(from: request.chainId) else {
            WCLogger.warning("Failed to create blockchain \(logSuffix)")
            throw WalletConnectV2Error.missingBlockchains([request.chainId.absoluteString])
        }

        // User wallet validation
        if userWalletRepository.models.isEmpty {
            WCLogger.warning("User wallet repository is locked")
            throw WalletConnectV2Error.userWalletRepositoryIsLocked
        }

        guard
            let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == connectedDApp.userWalletID })
        else {
            WCLogger.warning("Failed to find target user wallet")
            throw WalletConnectV2Error.missingActiveUserWalletModel
        }

        if userWalletModel.isUserWalletLocked {
            WCLogger.warning("Attempt to handle message with locked user wallet")
            throw WalletConnectV2Error.userWalletIsLocked
        }

        // Return validated request data
        return WCValidatedRequest(
            request: request,
            dAppData: connectedDApp.dAppData,
            targetBlockchain: targetBlockchain,
            userWalletModel: userWalletModel
        )
    }

    func makeHandleTransactionDTO(
        from validatedRequest: WCValidatedRequest,
        connectedBlockchains: [BlockchainSdk.Blockchain]
    ) async throws -> WCHandleTransactionDTO {
        let handler = try await getHandler(
            for: validatedRequest.request,
            blockchainId: validatedRequest.targetBlockchain.id,
            signer: validatedRequest.userWalletModel.signer,
            walletModelProvider: validatedRequest.userWalletModel.wcWalletModelProvider
        )

        guard let blockchain = connectedBlockchains.first(where: { $0.networkId == validatedRequest.targetBlockchain.id }) else { throw WalletConnectV2Error.missingActiveUserWalletModel }

        return WCHandleTransactionDTO(
            method: handler.method,
            rawTransaction: handler.rawTransaction,
            requestData: handler.requestData,
            blockchain: blockchain,
            accept: { try await handler.handle() },
            reject: { RPCResult.error(.init(code: 0, message: "User rejected sign")) },
            updatableHandler: handler as? WCTransactionUpdatable
        )
    }
}
