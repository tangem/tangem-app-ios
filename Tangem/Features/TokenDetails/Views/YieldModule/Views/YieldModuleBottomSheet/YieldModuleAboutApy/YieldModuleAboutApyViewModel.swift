//
//  YieldModuleAboutApyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

final class YieldModuleAboutApyViewModel {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    let baseApyText: String
    let rewardsAprText: String

    init(baseApy: Decimal, rewardsApr: Decimal) {
        let formatter = PercentFormatter()
        baseApyText = formatter.format(baseApy, option: .earn)
        rewardsAprText = formatter.format(rewardsApr, option: .earn)
    }

    func onCloseTap() {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.removeActiveSheet()
        }
    }
}

extension YieldModuleAboutApyViewModel: FloatingSheetContentViewModel {}
