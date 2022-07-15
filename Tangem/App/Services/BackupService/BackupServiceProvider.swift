//
//  BackupServiceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class BackupServiceProvider: BackupServiceProviding {
    @Injected(\.tangemSdkProvider) var sdkProvider: TangemSdkProviding

    lazy var backupService: BackupService = {
        .init(sdk: sdkProvider.sdk)
    }()
}
