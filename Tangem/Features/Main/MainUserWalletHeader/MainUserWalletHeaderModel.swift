//
//  MainUserWalletHeaderModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct MainUserWalletHeaderModel {
    let headerViewModel: MainHeaderViewModel
    let actionButtonsViewModel: ActionButtonsViewModel?
    let paginationState: PaginationState?

    struct PaginationState {
        let totalPages: Int
        let currentIndex: Int
    }
}
