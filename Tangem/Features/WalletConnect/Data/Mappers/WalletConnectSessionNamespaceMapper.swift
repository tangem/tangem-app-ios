//
//  WalletConnectSessionNamespaceMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct ReownWalletKit.SessionNamespace

enum WalletConnectSessionNamespaceMapper {
    static func mapToDomain(
        _ reownNamespaces: [String: ReownWalletKit.SessionNamespace]
    ) -> [String: WalletConnectDAppConnectionRequest.SessionNamespace] {
        reownNamespaces
            .mapValues { reownSessionNamespace in
                let blockchains = Set((reownSessionNamespace.chains ?? []).compactMap(WalletConnectBlockchainMapper.mapToDomain))

                return WalletConnectDAppConnectionRequest.SessionNamespace(
                    blockchains: blockchains,
                    accounts: reownSessionNamespace.accounts.map(WalletConnectAccountsMapper.mapToDomain),
                    methods: reownSessionNamespace.methods,
                    events: reownSessionNamespace.events
                )
            }
    }

    static func mapFromDomain(
        _ namespaces: [String: WalletConnectDAppConnectionRequest.SessionNamespace]
    ) -> [String: ReownWalletKit.SessionNamespace] {
        namespaces
            .mapValues { domainNamespace in
                return ReownWalletKit.SessionNamespace(
                    chains: domainNamespace.blockchains?.compactMap(WalletConnectBlockchainMapper.mapFromDomain),
                    accounts: domainNamespace.accounts.compactMap(WalletConnectAccountsMapper.mapFromDomain),
                    methods: domainNamespace.methods,
                    events: domainNamespace.events
                )
            }
    }
}
