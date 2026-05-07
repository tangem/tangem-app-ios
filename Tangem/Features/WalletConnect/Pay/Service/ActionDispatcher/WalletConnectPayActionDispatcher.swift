//
//  WalletConnectPayActionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift
import BlockchainSdk
import ReownWalletKit
import TangemFoundation

protocol WalletConnectPayActionDispatching {
    func dispatch(_ actions: [WalletConnectPayAction]) async throws -> [String]
}

struct WalletConnectPayActionDispatcher: WalletConnectPayActionDispatching {
    private let userWalletModel: any UserWalletModel
    private let accountId: String
    private let transactionBuilder: WCEthTransactionBuilder

    private var signer: WalletConnectSigner {
        CommonWalletConnectSigner(signer: userWalletModel.signer)
    }

    init(
        userWalletModel: any UserWalletModel,
        accountId: String,
        transactionBuilder: WCEthTransactionBuilder = CommonWCEthTransactionBuilder()
    ) {
        self.userWalletModel = userWalletModel
        self.accountId = accountId
        self.transactionBuilder = transactionBuilder
    }

    func dispatch(_ actions: [WalletConnectPayAction]) async throws -> [String] {
        var signatures: [String] = []
        signatures.reserveCapacity(actions.count)

        for action in actions {
            signatures.append(try await dispatch(action))
        }

        return signatures
    }

    private func dispatch(_ action: WalletConnectPayAction) async throws -> String {
        guard let method = WalletConnectMethod(rawValue: action.walletRpc.method) else {
            throw WalletConnectTransactionRequestProcessingError.unsupportedMethod(action.walletRpc.method)
        }

        switch method {
        case .sendTransaction:
            return try await sendTransaction(action.walletRpc)
        case .signTypedData, .signTypedDataV4:
            return try await signTypedData(action.walletRpc)
        case .personalSign:
            return try await personalSign(action.walletRpc)
        default:
            throw WalletConnectTransactionRequestProcessingError.unsupportedMethod(action.walletRpc.method)
        }
    }

    private func sendTransaction(_ rpc: WalletConnectPayWalletRPC) async throws -> String {
        let blockchain = try blockchain(from: rpc.chainId)
        let transactions = try decodeParams([WalletConnectEthTransaction].self, from: rpc.params)

        guard let wcTransaction = transactions.first else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(rpc.params)
        }

        let walletModel = try userWalletModel.wcAccountsWalletModelProvider.getModel(
            with: wcTransaction.from,
            blockchainId: blockchain.networkId,
            accountId: accountId
        )

        let transaction = try await transactionBuilder.buildTx(
            from: WCSendableTransaction(from: wcTransaction),
            for: walletModel
        )

        let dispatcher = WalletModelTransactionDispatcherProvider(
            walletModel: walletModel,
            signer: userWalletModel.signer
        )
        .makeTransferTransactionDispatcher()

        let result = try await dispatcher.send(transaction: .transfer(transaction))

        return result.hash.lowercased()
    }

    private func signTypedData(_ rpc: WalletConnectPayWalletRPC) async throws -> String {
        let blockchain = try blockchain(from: rpc.chainId)
        let params = try decodeParams([String].self, from: rpc.params)

        guard params.count >= 2 else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(rpc.params)
        }

        let targetAddress = params[0]
        let message = params[1]
        let walletModel = try userWalletModel.wcAccountsWalletModelProvider.getModel(
            with: targetAddress,
            blockchainId: blockchain.networkId,
            accountId: accountId
        )

        guard
            let messageData = message.data(using: .utf8),
            let typedData = try? JSONDecoder().decode(EIP712TypedData.self, from: messageData)
        else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(rpc.params)
        }

        let signedHash = try await signer.sign(data: typedData.signHash, using: walletModel)
        return signedHash.hexString.addHexPrefix().lowercased()
    }

    private func personalSign(_ rpc: WalletConnectPayWalletRPC) async throws -> String {
        let blockchain = try blockchain(from: rpc.chainId)
        let params = try decodeParams([String].self, from: rpc.params)

        guard params.count >= 2 else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(rpc.params)
        }

        let targetAddress = params[1]
        let walletModel = try userWalletModel.wcAccountsWalletModelProvider.getModel(
            with: targetAddress,
            blockchainId: blockchain.networkId,
            accountId: accountId
        )

        let message = params[0]
        let dataToSign = makePersonalSignData(from: message)
        let hash = makePersonalMessageData(dataToSign).sha3(.keccak256)
        let signedMessage = try await signer.sign(data: hash, using: walletModel)

        return signedMessage.hexString.addHexPrefix().lowercased()
    }

    private func blockchain(from caipChainId: String) throws -> BlockchainSdk.Blockchain {
        let components = caipChainId.split(separator: ":", maxSplits: 1).map(String.init)

        guard components.count == 2 else {
            throw WalletConnectTransactionRequestProcessingError.unsupportedBlockchain(caipChainId)
        }

        guard
            let reownBlockchain = ReownWalletKit.Blockchain(namespace: components[0], reference: components[1]),
            let blockchain = WalletConnectBlockchainMapper.mapToDomain(reownBlockchain)
        else {
            throw WalletConnectTransactionRequestProcessingError.unsupportedBlockchain(caipChainId)
        }

        return blockchain
    }

    private func decodeParams<T: Decodable>(_ type: T.Type, from params: String) throws -> T {
        guard let data = params.data(using: .utf8) else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(params)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(params)
        }
    }

    private func makePersonalSignData(from message: String) -> Data {
        let hexData = Data([UInt8](hex: message))

        if hexData.isEmpty, !message.hasHexPrefix() {
            return message.data(using: .utf8) ?? Data()
        }

        return hexData
    }

    private func makePersonalMessageData(_ data: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + "\(data.count)").data(using: .utf8)!
        return prefixData + data
    }
}
