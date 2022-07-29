//
//  DefaultFooterView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultFooterView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.footnote)
            .foregroundColor(Colors.Text.tertiary)
    }
}
