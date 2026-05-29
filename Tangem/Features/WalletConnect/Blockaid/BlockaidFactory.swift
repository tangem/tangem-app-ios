//
//  BlockaidDependenciesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

final class BlockaidFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeBlockaidAPIService() -> BlockaidAPIService {
        let provider = TangemProvider<BlockaidTarget>(
            configuration: TangemProviderConfiguration(
                logOptions: .verbose,
                urlSessionConfiguration: .ephemeralConfiguration
            )
        )
        return CommonBlockaidAPIService(
            provider: provider,
            credential: BlockaidAPICredential(
                apiKey: keysManager.blockaidAPIKey
            )
        )
    }
}
