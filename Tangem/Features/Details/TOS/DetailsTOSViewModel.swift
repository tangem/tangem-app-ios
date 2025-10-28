//
//  DetailsTOSViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class DetailsTOSViewModel {
    let navigationTitle = Localization.disclaimerTitle

    let tosViewModel: TOSViewModel

    init() {
        tosViewModel = TOSViewModel(bottomOverlayHeight: 0)
    }
}
