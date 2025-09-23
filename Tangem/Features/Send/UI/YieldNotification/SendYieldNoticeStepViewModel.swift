//
//  SendYieldNoticeStepViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

final class SendYieldNoticeStepViewModel {
    @Injected(\.floatingSheetPresenter) var floatingSheetPresenter: FloatingSheetPresenter

    private(set) var currencySymbol: String
    private(set) var tokenIconInfo: TokenIconInfo
    private let action: () -> Void

    init(tokenItem: TokenItem, action: @escaping () -> Void) {
        currencySymbol = tokenItem.currencySymbol
        tokenIconInfo = TokenIconInfoBuilder().build(from: tokenItem.id)
        self.action = action
    }

    func didTapClose() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func didTapButton() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            action()
        }
    }
}

extension SendYieldNoticeStepViewModel: FloatingSheetContentViewModel {}
