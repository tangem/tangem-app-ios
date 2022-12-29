//
//  CheckIconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct CheckIconView: View {
    @Binding private var isSelected: Bool

    init(isSelected: Binding<Bool>) {
        _isSelected = isSelected
    }

    var body: some View {
        Assets.check
            .resizable()
            .foregroundColor(Colors.Control.checked)
            /// Need to cover empty place if unchecking
            .opacity(isSelected ? 1 : 0)
            .frame(width: 20, height: 20)
    }
}
