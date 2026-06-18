//
//  TangemRowDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemRowDemoViewModel: ObservableObject, Identifiable {}

struct TangemRowDemoView: View {
    @ObservedObject var viewModel: TangemRowDemoViewModel

    var body: some View {
        TangemRowShowcase()
            .navigationBarTitle(Text("TangemRow"))
    }
}
