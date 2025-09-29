//
//  YieldModuleBalanceInfoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemUI

@MainActor
final class YieldModuleBalanceInfoViewModel {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) var floatingSheetPresenter: FloatingSheetPresenter

    private(set) var params: YieldModuleViewConfigs.BalanceInfoParams

    // MARK: - Init

    init(params: YieldModuleViewConfigs.BalanceInfoParams) {
        self.params = params
    }

    // MARK: - Public Implementation

    func onCloseTap() {
        runTask(in: self) { vm in
            vm.floatingSheetPresenter.removeActiveSheet()
        }
    }

    func getTokenIconInfo() -> TokenIconInfo {
        TokenIconInfoBuilder().build(from: params.tokenItem, isCustom: false)
    }
}

extension YieldModuleBalanceInfoViewModel: FloatingSheetContentViewModel {}
