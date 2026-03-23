//
//  WalletConnectBitcoinGetAccountAddressesHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

final class WalletConnectBitcoinGetAccountAddressesHandler {
    private let request: AnyCodable
    private let walletModel: any WalletModel
    private let intentions: [String]

    init(
        request: AnyCodable,
        blockchainId: String,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        self.request = request

        // Parse optional intentions; default to empty (no filtering)
        let parsedIntentions: [String]
        do {
            let params = try request.get(WalletConnectBtcGetAccountAddressesRequest.self)
            parsedIntentions = params.intentions ?? []
        } catch {
            parsedIntentions = []
        }
        intentions = parsedIntentions.map { $0.lowercased() }

        guard let model = walletModelProvider.getModel(with: blockchainId) else {
            throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
        }
        walletModel = model
    }

    init(
        request: AnyCodable,
        blockchainId: String,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        self.request = request

        // Parse optional intentions; default to empty (no filtering)
        let parsedIntentions: [String]
        do {
            let params = try request.get(WalletConnectBtcGetAccountAddressesRequest.self)
            parsedIntentions = params.intentions ?? []
        } catch {
            parsedIntentions = []
        }
        intentions = parsedIntentions.map { $0.lowercased() }

        guard let model = wcAccountsWalletModelProvider.getModel(with: blockchainId, accountId: accountId) else {
            throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
        }
        walletModel = model
    }
}

// MARK: - WalletConnectMessageHandler

extension WalletConnectBitcoinGetAccountAddressesHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .getAccountAddresses }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    var requestData: Data {
        (try? JSONEncoder().encode(intentionObjects)) ?? Data()
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> JSONRPC.RPCResult {
        // If the only intention is "ordinal" – return empty list
        if Set(intentions) == ["ordinal"] {
            return .response(AnyCodable(any: []))
        }

        let pathString = walletModel.tokenItem.blockchainNetwork.derivationPath?.rawPath

        let responses: [WalletConnectBtcAccountAddressResponse] = walletModel.addresses.map {
            WalletConnectBtcAccountAddressResponse(
                address: $0.value,
                path: pathString,
                intention: "payment" // Always "payment" per requirements. We don't support ordinals
            )
        }

        return .response(AnyCodable(responses))
    }
}

// MARK: - Private

private extension WalletConnectBitcoinGetAccountAddressesHandler {
    /// For requestData echoing
    var intentionObjects: WalletConnectBtcGetAccountAddressesRequest {
        WalletConnectBtcGetAccountAddressesRequest(intentions: intentions)
    }
}

// MARK: - Models

struct WalletConnectBtcGetAccountAddressesRequest: Codable {
    /// Optional filter of intentions: "payment", "ordinal"
    let intentions: [String]?
}

struct WalletConnectBtcAccountAddressResponse: Codable {
    let address: String
    /// Optional derivation path like "m/84'/0'/0'/0/0"
    let path: String?
    /// Always "payment" as per requirements
    let intention: String
}
