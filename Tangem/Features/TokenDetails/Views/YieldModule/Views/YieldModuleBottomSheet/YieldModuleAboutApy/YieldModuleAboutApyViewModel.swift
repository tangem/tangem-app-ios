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
    let usesIncentiveDesign: Bool

    init(baseApy: Decimal, rewardsApr: Decimal, usesIncentiveDesign: Bool) {
        let formatter = PercentFormatter()
        baseApyText = formatter.format(baseApy, option: .earn)
        rewardsAprText = formatter.format(rewardsApr, option: .earn)
        self.usesIncentiveDesign = usesIncentiveDesign
    }

    func onCloseTap() {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.removeActiveSheet()
        }
    }
}

extension YieldModuleAboutApyViewModel: FloatingSheetContentViewModel {}
