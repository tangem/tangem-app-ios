//
//  TangemSearchFieldDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemSearchFieldDemoViewModel: ObservableObject, Identifiable {}

struct TangemSearchFieldDemo: View {
    @ObservedObject var viewModel: TangemSearchFieldDemoViewModel

    var body: some View {
        TangemSearchFieldShowcase()
            .navigationBarTitle(Text("TangemSearchField"))
    }
}
