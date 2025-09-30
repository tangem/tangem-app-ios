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

    private(set) var tokenName: String
    private(set) var tokenId: String?

    // MARK: - Init

    init(tokenName: String, tokenId: String?) {
        self.tokenName = tokenName
        self.tokenId = tokenId
    }

    // MARK: - Public Implementation

    func onCloseTap() {
        runTask(in: self) { vm in
            vm.floatingSheetPresenter.removeActiveSheet()
        }
    }
}

extension YieldModuleBalanceInfoViewModel: FloatingSheetContentViewModel {}
