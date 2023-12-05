//
//  ExpressAPIProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping

struct CommonExpressAPIFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeExpressAPIProvider(userId: String = UUID().uuidString) -> ExpressAPIProvider {
        let factory = TangemSwappingFactory()
        let credentials = ExpressAPICredential(
            apiKey: keysManager.tangemExpressApiKey,
            userId: userId,
            sessionId: UUID().uuidString
        )

        return factory.makeExpressAPIProvider(
            credential: credentials,
            configuration: .defaultConfiguration,
            logger: AppLog.shared
        )
    }
}
