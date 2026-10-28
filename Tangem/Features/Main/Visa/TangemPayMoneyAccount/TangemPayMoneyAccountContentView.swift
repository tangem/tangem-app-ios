//
//  TangemPayMoneyAccountContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemPayMoneyAccountContentView: View {
    let state: TangemPayMoneyAccountStateModel
    let action: (TangemPayMoneyAccountAction) -> Void

    var body: some View {}
}

#Preview {
    let state = TangemPayMoneyAccountStateModel()

    TangemPayMoneyAccountContentView(
        state: state,
        action: { _ in }
    )
}
