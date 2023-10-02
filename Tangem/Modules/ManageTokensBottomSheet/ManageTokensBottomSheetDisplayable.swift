//
//  ManageTokensBottomSheetDisplayable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ManageTokensBottomSheetDisplayable: AnyObject {
    func coordinator(
        _ coordinator: any CoordinatorObject,
        wantsToShowManageTokensBottomSheetWithViewModel viewModel: ManageTokensBottomSheetViewModel
    )

    func coordinatorWantsToHideManageTokensBottomSheet(
        _ coordinator: any CoordinatorObject
    )
}
