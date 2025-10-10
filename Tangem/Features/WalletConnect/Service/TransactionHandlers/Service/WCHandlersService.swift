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
    func validate(
        request: Request,
        forConnectedDApp connectedDApp: WalletConnectConnectedDApp
    ) throws(WalletConnectTransactionRequestProcessingError) -> WCValidatedRequest

    func makeHandleTransactionDTO(
        from validatedRequest: WCValidatedRequest,
        connectedDApp: WalletConnectConnectedDApp
    ) throws -> WCHandleTransactionDTO
}

final class CommonWCHandlersService {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let wcHandlersFactory: WalletConnectHandlersCreator

    init(wcHandlersFactory: WalletConnectHandlersCreator) {
        self.wcHandlersFactory = wcHandlersFactory
    }

    private func getHandler(
        for request: Request,
        blockchain: BlockchainSdk.Blockchain,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider,
        connectedDApp: WalletConnectConnectedDApp
    ) throws -> WalletConnectMessageHandler {
        let method = request.method

        guard let wcAction = WalletConnectMethod(rawValue: method) else {
            throw WalletConnectTransactionRequestProcessingError.unsupportedMethod(method)
        }

        return try wcHandlersFactory.createHandler(
            for: wcAction,
            with: request.params,
            blockchainNetworkID: blockchain.networkId,
            signer: signer,
            walletModelProvider: walletModelProvider,
            connectedDApp: connectedDApp
        )
    }
}

// MARK: - WCHandlersService

extension CommonWCHandlersService: WCHandlersService {
    func validate(
        request: Request,
        forConnectedDApp connectedDApp: WalletConnectConnectedDApp
    ) throws(WalletConnectTransactionRequestProcessingError) -> WCValidatedRequest {
        guard let targetBlockchain = WalletConnectBlockchainMapper.mapToDomain(request.chainId) else {
            WCLogger.warning("Failed to create blockchain for request: \(request.id)")
            throw WalletConnectTransactionRequestProcessingError.unsupportedBlockchain(request.chainId.absoluteString)
        }

        if userWalletRepository.models.isEmpty {
            WCLogger.warning("User wallet repository is locked")
            throw WalletConnectTransactionRequestProcessingError.userWalletRepositoryIsLocked
        }

        guard
            let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == connectedDApp.userWalletID })
        else {
            WCLogger.warning("Failed to find target user wallet")
            throw WalletConnectTransactionRequestProcessingError.userWalletNotFound
        }

        if userWalletModel.isUserWalletLocked {
            WCLogger.warning("Attempt to handle message with locked user wallet")
            throw WalletConnectTransactionRequestProcessingError.userWalletIsLocked
        }

        return WCValidatedRequest(
            request: request,
            dAppData: connectedDApp.dAppData,
            targetBlockchain: targetBlockchain,
            userWalletModel: userWalletModel
        )
    }

    func makeHandleTransactionDTO(
        from validatedRequest: WCValidatedRequest,
        connectedDApp: WalletConnectConnectedDApp
    ) throws -> WCHandleTransactionDTO {
        let handler = try getHandler(
            for: validatedRequest.request,
            blockchain: validatedRequest.targetBlockchain,
            signer: validatedRequest.userWalletModel.signer,
            walletModelProvider: validatedRequest.userWalletModel.wcWalletModelProvider,
            connectedDApp: connectedDApp
        )

        guard let blockchain = connectedDApp.dAppBlockchains
            .map(\.blockchain)
            .first(where: { $0.networkId == validatedRequest.targetBlockchain.networkId })
        else {
            throw WalletConnectTransactionRequestProcessingError.userWalletNotFound
        }

        return WCHandleTransactionDTO(
            method: handler.method,
            rawTransaction: handler.rawTransaction,
            requestData: handler.requestData,
            blockchain: blockchain,
            verificationStatus: connectedDApp.verificationStatus,
            accept: { try await handler.handle() },
            reject: { RPCResult.error(.init(code: 0, message: "User rejected sign")) },
            updatableHandler: handler as? WCTransactionUpdatable
        )
    }
}
