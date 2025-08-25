//
//  VisaUtilities+FeatureStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemVisa

extension VisaUtilities {
    init() {
        self = VisaUtilities(isTestnet: FeatureStorage.instance.visaAPIType.isTestnet)
    }
}
