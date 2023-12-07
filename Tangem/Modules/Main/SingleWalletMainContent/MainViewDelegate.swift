//
//  MainViewDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
protocol MainViewDelegate: MainNotificationsObserver {
    func present(actionSheet: ActionSheetBinder)
}
