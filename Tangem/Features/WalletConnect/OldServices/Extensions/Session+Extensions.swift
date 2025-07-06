//
//  Session+Extensions.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Date
import TangemFoundation
import ReownWalletKit

extension Session.Proposal {
    var namespaceRequiredChains: Set<WalletConnectUtils.Blockchain> {
        Set(requiredNamespaces.values.compactMap(\.chains).flatMap { $0 })
    }

    var namespaceChains: [WalletConnectUtils.Blockchain] {
        let requiredChains = requiredNamespaces.values.compactMap(\.chains).flatMap { $0 }
        let optionalChains = optionalNamespaces?.values.compactMap(\.chains).flatMap { $0 } ?? []

        return requiredChains + optionalChains
    }

    var namespaceMethods: [String] {
        let requiredMethods = requiredNamespaces.values.flatMap { $0.methods.toArray() }
        let optionalMethods = optionalNamespaces?.values.flatMap { $0.methods.toArray() } ?? []

        return requiredMethods + optionalMethods
    }

    var namespaceEvents: [String] {
        let requiredEvents = requiredNamespaces.values.flatMap { $0.events.toArray() }
        let optionalEvents = optionalNamespaces?.values.flatMap { $0.events.toArray() } ?? []

        return requiredEvents + optionalEvents
    }
}

extension Session {
    func mapToWCSavedSession(with userWalletId: String) -> WalletConnectSavedSession {
        let dApp = peer
        let dAppInfo = WalletConnectSavedSession.DAppInfo(
            name: dApp.name,
            description: dApp.description,
            url: dApp.url,
            iconLinks: dApp.icons
        )
        let sessionInfo = WalletConnectSavedSession.SessionInfo(
            dAppInfo: dAppInfo
        )

        let connectedBlockchains = namespaces
            .values
            .flatMap { $0.chains ?? [] }
            .compactMap(WalletConnectBlockchainMapper.mapToDomain)

        return WalletConnectSavedSession(
            userWalletId: userWalletId,
            connectionDate: Date.now,
            connectedBlockchains: connectedBlockchains,
            topic: topic,
            sessionInfo: sessionInfo
        )
    }
}
