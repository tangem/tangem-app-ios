//
//  GeneralFeeProviderFeesLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol GeneralFeeProviderFeesLoader {
    func reloadFee() async throws -> [BSDKFee]
}

enum FeeProviderFeesLoaderError: LocalizedError {
    case requiredDataNotFound
}
