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
        hardwareLimitationsUtil: HardwareLimitationsUtil,
        walletModelProvider: WalletConnectWalletModelProvider,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
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
            hardwareLimitationsUtil: hardwareLimitationsUtil,
            walletModelProvider: walletModelProvider,
            wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
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

        let userWalletModel: any UserWalletModel

        userWalletModel = try WCUserWalletModelFinder.findUserWalletModel(
            connectedDApp: connectedDApp,
            userWalletModels: userWalletRepository.models
        )

        if userWalletModel.isUserWalletLocked {
            WCLogger.warning("Attempt to handle message with locked user wallet")
            throw WalletConnectTransactionRequestProcessingError.userWalletIsLocked
        }

        let account: (any CryptoAccountModel)?

        if FeatureProvider.isAvailable(.accounts), let accountId = connectedDApp.accountId {
            account = WCAccountFinder.findCryptoAccountModel(
                by: accountId,
                accountModelsManager: userWalletModel.accountModelsManager
            )
        } else {
            account = nil
        }

        return WCValidatedRequest(
            request: request,
            dAppData: connectedDApp.dAppData,
            targetBlockchain: targetBlockchain,
            userWalletModel: userWalletModel,
            account: account
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
            hardwareLimitationsUtil: HardwareLimitationsUtil(config: validatedRequest.userWalletModel.config),
            walletModelProvider: validatedRequest.userWalletModel.wcWalletModelProvider,
            wcAccountsWalletModelProvider: validatedRequest.userWalletModel.wcAccountsWalletModelProvider,
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
            validate: { try await handler.validate() },
            accept: { try await handler.handle() },
            reject: { RPCResult.error(.init(code: 0, message: "User rejected sign")) },
            updatableHandler: handler as? WCTransactionUpdatable
        )
    }
}
