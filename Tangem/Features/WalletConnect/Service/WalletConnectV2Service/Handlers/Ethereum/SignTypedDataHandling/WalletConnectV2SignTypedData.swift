//
//  WalletConnectV2SignTypedData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import enum BlockchainSdk.Blockchain
import struct BlockchainSdk.EIP712TypedData
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

struct WalletConnectV2SignTypedDataHandler {
    private let message: String
    private let typedData: EIP712TypedData
    private let signer: WalletConnectSigner
    private let walletModel: any WalletModel
    private let request: AnyCodable

    init(
        requestParams: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        let params = try requestParams.get([String].self)

        guard params.count >= 2 else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(requestParams.description)
        }

        message = params[1]

        let targetAddress = params[0]

        let walletModel = try wcAccountsWalletModelProvider.getModel(
            with: targetAddress,
            blockchainId: blockchainId,
            accountId: accountId
        )

        guard
            let messageData = message.data(using: .utf8),
            let typedData = try? JSONDecoder().decode(EIP712TypedData.self, from: messageData)
        else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(requestParams.description)
        }

        try Self.ensureSigningAllowed(for: typedData, signerAddress: walletModel.walletConnectAddress)

        self.typedData = typedData
        self.walletModel = walletModel
        self.signer = signer
        request = requestParams
    }
}

extension WalletConnectV2SignTypedDataHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .signTypedData }

    var requestData: Data {
        message.data(using: .utf8) ?? Data()
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> RPCResult {
        try Self.ensureSigningAllowed(for: typedData, signerAddress: walletModel.walletConnectAddress)

        let hash = typedData.signHash

        let signedHash = try await signer.sign(data: hash, using: walletModel)
        return .response(AnyCodable(signedHash.hexString.addHexPrefix().lowercased()))
    }
}

private extension WalletConnectV2SignTypedDataHandler {
    static func ensureSigningAllowed(for typedData: EIP712TypedData, signerAddress: String) throws {
        do {
            try WCEthTypedDataValidator().validate(typedData, signerAddress: signerAddress)
        } catch {
            throw WalletConnectTransactionRequestProcessingError.forbiddenTypedData(error)
        }
    }
}
