//
//  TangemButtonV2Demo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemButtonV2DemoViewModel: ObservableObject, Identifiable {}

struct TangemButtonV2DemoView: View {
    @ObservedObject var viewModel: TangemButtonV2DemoViewModel

    var body: some View {
        ButtonShowcase()
            .navigationBarTitle(Text("TangemUI.Button"))
    }
}
