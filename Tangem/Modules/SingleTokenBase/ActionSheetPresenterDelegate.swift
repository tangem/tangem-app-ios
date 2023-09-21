//
//  ActionSheetPresenterDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionSheetPresenterDelegate: AnyObject {
    func present(actionSheet: ActionSheetBinder)
}
