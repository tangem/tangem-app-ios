//
//  ManageTokensBottomSheetIntermediateDisplayable+CoordinatorObject
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Convinience extension for passing Manage Tokens bottom sheet commands up the coordinator chain (from child to parent).
extension ManageTokensBottomSheetIntermediateDisplayable where Self: CoordinatorObject {
    func coordinator(
        _ coordinator: any CoordinatorObject,
        wantsToShowManageTokensBottomSheetWithViewModel viewModel: ManageTokensBottomSheetViewModel
    ) {
        nextManageTokensBottomSheetDisplayable?.coordinator(self, wantsToShowManageTokensBottomSheetWithViewModel: viewModel)
    }

    func coordinatorWantsToHideManageTokensBottomSheet(
        _ coordinator: any CoordinatorObject
    ) {
        nextManageTokensBottomSheetDisplayable?.coordinatorWantsToHideManageTokensBottomSheet(self)
    }
}
