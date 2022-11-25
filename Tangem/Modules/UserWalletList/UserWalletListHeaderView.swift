//
//  UserWalletListHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct UserWalletListHeaderView: View {
    let name: String

    var body: some View {
        Text(name)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 10, trailing: 16))
            .frame(height: 37)
    }
}
