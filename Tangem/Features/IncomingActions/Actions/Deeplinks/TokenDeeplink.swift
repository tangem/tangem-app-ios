//
//  TokenDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://token?token_id&network_id[&user_wallet_id&derivation_path&type&transaction_id]`
struct TokenDeeplink: HostNamedDeeplink, Equatable {
    static let host = "token"

    let tokenId: String
    let networkId: String
    let userWalletId: String?
    let derivationPath: String?
    let statusUpdate: StatusUpdate?

    var action: DeeplinkNavigationAction { .token(self) }

    init(
        tokenId: String,
        networkId: String,
        userWalletId: String? = nil,
        derivationPath: String? = nil,
        statusUpdate: StatusUpdate? = nil
    ) {
        self.tokenId = tokenId
        self.networkId = networkId
        self.userWalletId = userWalletId
        self.derivationPath = derivationPath
        self.statusUpdate = statusUpdate
    }
}

// MARK: - Types

extension TokenDeeplink {
    struct StatusUpdate: Equatable {
        let kind: Kind
        let transactionId: String

        enum Kind {
            case onramp
            case swap
        }
    }
}

// MARK: - Parsing

extension TokenDeeplink {
    /// Parameters only a token link carries. Shared with the builder that turns a transaction push into one.
    enum Keys {
        static let type = "type"
        static let transactionId = "transaction_id"
    }

    init(link: DeeplinkURL) throws {
        let query = link.query

        tokenId = try query.required(Shared.tokenId, lowercased: true)
        networkId = try query.required(Shared.networkId, lowercased: true)
        userWalletId = query.unchecked(Shared.userWalletId)
        derivationPath = query.unchecked(Shared.derivationPath)

        guard
            let type = query.unchecked(Keys.type).flatMap(IncomingActionConstants.DeeplinkType.init(rawValue:)),
            let kind = StatusUpdate.Kind(type)
        else {
            statusUpdate = nil
            return
        }

        // A status link points at one transaction of one derived address, and can't be opened without either.
        guard derivationPath != nil else {
            throw DeeplinkQuery.ValidationError.missingValue(key: Shared.derivationPath)
        }

        guard let transactionId = query.unchecked(Keys.transactionId) else {
            throw DeeplinkQuery.ValidationError.missingValue(key: Keys.transactionId)
        }

        statusUpdate = StatusUpdate(kind: kind, transactionId: transactionId)
    }
}

private extension TokenDeeplink.StatusUpdate.Kind {
    init?(_ type: IncomingActionConstants.DeeplinkType) {
        switch type {
        case .onrampStatusUpdate:
            self = .onramp
        case .swapStatusUpdate:
            self = .swap
        case .incomeTransaction:
            return nil
        }
    }
}

// MARK: - Navigation

extension TokenDeeplink {
    /// The token this link points at. When it isn't in the portfolio yet — it may have been added on another
    /// device — the user token list is synced once and the wallet model is waited for before giving up.
    ///
    /// - Note: no interactive key derivation happens here, so a token that needs a key this wallet doesn't
    ///   have yet stays unfound.
    /// The wallet the link names, or the selected one when it names none. Asked before the link is claimed:
    /// the token itself can be waited for, a wallet that isn't on this device cannot.
    @MainActor
    func findUserWalletModel() -> (any UserWalletModel)? {
        DeeplinkWalletModelLocator().findUserWalletModel(userWalletModelId: userWalletId)
    }

    @MainActor
    func findTarget() async -> DeeplinkWalletModelLocator.Target? {
        let target = await DeeplinkWalletModelLocator().findTarget(
            userWalletId: userWalletId,
            tokenId: tokenId,
            networkId: networkId,
            derivationPath: derivationPath,
            syncingTokenList: true
        )

        guard let target, TokenActionAvailabilityProvider(
            userWalletInfo: target.userWalletModel.userWalletInfo,
            walletModel: target.walletModel
        ).isTokenInteractionAvailable() else {
            return nil
        }

        return target
    }

    var pendingTransactionDetails: PendingTransactionDetails? {
        guard let statusUpdate else {
            return nil
        }

        let type: PendingTransactionDetails.TransactionType

        switch statusUpdate.kind {
        case .onramp: type = .onramp
        case .swap: type = .swap
        }

        return PendingTransactionDetails(type: type, id: statusUpdate.transactionId)
    }
}
