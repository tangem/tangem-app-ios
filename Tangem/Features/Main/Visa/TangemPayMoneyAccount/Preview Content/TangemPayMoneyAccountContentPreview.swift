//
//  TangemPayMoneyAccountContentPreview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG
import SwiftUI
import TangemUI

struct TangemPayMoneyAccountContentPreview: View {
    let state: TangemPayMoneyAccountStateModel

    @StateObject private var refreshScrollState = RefreshScrollViewStateObject(refreshable: {})

    var body: some View {
        NavigationStack {
            TangemPayMoneyAccountContentView(
                state: state,
                refreshScrollState: refreshScrollState,
                action: { _ in }
            )
            .tangemPayMoneyAccountToolbar(
                menuSections: TangemPayMoneyAccountPreviewData.menuSections,
                onMenuItemSelected: { _ in }
            )
        }
    }
}
#endif // DEBUG
