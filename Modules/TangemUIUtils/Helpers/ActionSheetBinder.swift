//
//  ActionSheetBinder.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

public struct ActionSheetBinder: Identifiable {
    public let id = UUID()

    public let sheet: ActionSheet

    public init(sheet: ActionSheet) {
        self.sheet = sheet
    }
}
