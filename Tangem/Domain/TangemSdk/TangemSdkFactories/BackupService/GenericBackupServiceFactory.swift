//
//  GenericBackupServiceFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class GenericBackupServiceFactory: BackupServiceFactory {
    private let isAccessCodeSet: Bool
    private let defaultBlockchains: [TokenItem]
    
    init(isAccessCodeSet: Bool, defaultBlockchains: [TokenItem]) {
        self.isAccessCodeSet = isAccessCodeSet
        self.defaultBlockchains = defaultBlockchains
    }

    func makeBackupService() -> BackupService {
        let factory = GenericTangemSdkFactory(isAccessCodeSet: isAccessCodeSet)
        let sdk = factory.makeTangemSdk()
        sdk.config.defaultDerivationPaths = DefaultDerivationsHelper().makeDefaultDerivations(defaultBlockchains: defaultBlockchains)
        return BackupService(
            sdk: sdk,
            networkService: TangemSdkNetworkServiceFactory().makeService()
        )
    }
}
