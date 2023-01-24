//
//  AnalyticsAdditionalDataRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    class AdditionalDataRepository {
        var cardDidScanEvent: Analytics.Event?
        var signedInCardIdentifiers: Set<String> = []
    }
}
