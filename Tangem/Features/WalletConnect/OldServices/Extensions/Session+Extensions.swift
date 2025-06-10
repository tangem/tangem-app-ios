//
//  Session+Extensions.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Date
import ReownWalletKit

extension Session.Proposal {
    var namespaceRequiredChains: Set<WalletConnectUtils.Blockchain> {
        Set(requiredNamespaces.values.compactMap(\.chains).flatMap { $0 })
    }

    var nameSpaceOptionalChains: Set<WalletConnectUtils.Blockchain> {
        Set(optionalNamespaces?.values.compactMap(\.chains).flatMap { $0 } ?? [])
    }

    var namespaceChains: [WalletConnectUtils.Blockchain] {
        let requiredChains = requiredNamespaces.values.compactMap(\.chains).flatMap { $0.asArray }
        let optionalChains = optionalNamespaces?.values.compactMap(\.chains).flatMap { $0.asArray } ?? []

        return requiredChains + optionalChains
    }

    var namespaceMethods: [String] {
        let requiredMethods = requiredNamespaces.values.flatMap { $0.methods.asArray }
        let optionalMethods = optionalNamespaces?.values.flatMap { $0.methods.asArray } ?? []

        return requiredMethods + optionalMethods
    }

    var namespaceEvents: [String] {
        let requiredEvents = requiredNamespaces.values.flatMap { $0.events.asArray }
        let optionalEvents = optionalNamespaces?.values.flatMap { $0.events.asArray } ?? []

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
            .compactMap(WCUtils.makeBlockchain)

        return WalletConnectSavedSession(
            userWalletId: userWalletId,
            connectionDate: Date.now,
            connectedBlockchains: connectedBlockchains,
            topic: topic,
            sessionInfo: sessionInfo
        )
    }
}
