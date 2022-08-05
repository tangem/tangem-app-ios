//
//  List+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

extension List {
    @ViewBuilder func groupedListStyleCompact() -> some View {
        if #available(iOS 14.0, *) {
            self.listStyle(.insetGrouped)
        } else {
            self.listStyle(.grouped)
        }
    }
}
