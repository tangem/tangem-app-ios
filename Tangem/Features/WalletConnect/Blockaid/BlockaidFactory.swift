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
        
        let provider = MoyaProvider<BlockaidTarget>(
            session: Session(configuration: .ephemeralConfiguration),
            plugins: plugins
        )
        return CommonBlockaidAPIService(
            provider: provider,
            credential: BlockaidAPICredential(
                apiKey: keysManager.blockaidKey
            )
        )
    }
}
