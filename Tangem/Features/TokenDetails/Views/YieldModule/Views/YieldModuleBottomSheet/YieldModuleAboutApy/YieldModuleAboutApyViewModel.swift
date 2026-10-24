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
    let rewardsApyText: String
    let usesIncentiveDesign: Bool

    init(baseApy: Decimal, rewardsApy: Decimal, usesIncentiveDesign: Bool) {
        let formatter = PercentFormatter()
        baseApyText = formatter.format(baseApy, option: .earn)
        rewardsApyText = formatter.format(rewardsApy, option: .earn)
        self.usesIncentiveDesign = usesIncentiveDesign
    }

    func onCloseTap() {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.removeActiveSheet()
        }
    }
}

extension YieldModuleAboutApyViewModel: FloatingSheetContentViewModel {}
