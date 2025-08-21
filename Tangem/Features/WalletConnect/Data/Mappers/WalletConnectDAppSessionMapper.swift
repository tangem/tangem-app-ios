//
//  WalletConnectDAppSessionMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct ReownWalletKit.Session

enum WalletConnectDAppSessionMapper {
    static func mapToDomain(
        _ reownSession: ReownWalletKit.Session,
        domainNamespaces: [String: WalletConnectSessionNamespace]
    ) -> WalletConnectDAppSession {
        WalletConnectDAppSession(topic: reownSession.topic, namespaces: domainNamespaces, expiryDate: reownSession.expiryDate)
    }
}
