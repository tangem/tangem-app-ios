//
//  TangemTabsDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemTabsDemoModel: ObservableObject, Identifiable {}

struct TangemTabsDemo: View {
    @ObservedObject var viewModel: TangemTabsDemoModel

    var body: some View {
        TangemTabsShowcase()
            .navigationBarTitle(Text("TangemTabs"))
    }
}
