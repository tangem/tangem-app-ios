//
//  TangemTokenRowDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemTokenRowDemoViewModel: ObservableObject, Identifiable {}

struct TangemTokenRowDemoView: View {
    @ObservedObject var viewModel: TangemTokenRowDemoViewModel

    var body: some View {
        TangemTokenRowShowcase()
            .navigationBarTitle(Text("TangemTokenRow"))
    }
}
