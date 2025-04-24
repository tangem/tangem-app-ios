//
//  BlockaidDependenciesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import Moya

final class BlockaidFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeBlockaidAPIService() -> BlockaidAPIService {
        let plugins: [PluginType] = [
            TangemNetworkLoggerPlugin(logOptions: .verbose),
        ]

        let provider = TangemProvider<BlockaidTarget>(
            plugins: plugins,
            sessionConfiguration: .ephemeralConfiguration
        )
        return CommonBlockaidAPIService(
            provider: provider,
            credential: BlockaidAPICredential(
                apiKey: keysManager.blockaidAPIKey
            )
        )
    }
}
