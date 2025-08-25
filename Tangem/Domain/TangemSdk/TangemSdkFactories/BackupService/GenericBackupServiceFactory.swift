//
//  GenericBackupServiceFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import TangemNetworkUtils

class GenericBackupServiceFactory: BackupServiceFactory {
    private let isAccessCodeSet: Bool

    init(isAccessCodeSet: Bool) {
        self.isAccessCodeSet = isAccessCodeSet
    }

    func makeBackupService() -> BackupService {
        let factory = GenericTangemSdkFactory(isAccessCodeSet: isAccessCodeSet)
        let sdk = factory.makeTangemSdk()
        return BackupService(sdk: sdk, networkService: .init(session: TangemTrustEvaluatorUtil.sharedSession, additionalHeaders: DeviceInfo().asHeaders()))
    }
}
