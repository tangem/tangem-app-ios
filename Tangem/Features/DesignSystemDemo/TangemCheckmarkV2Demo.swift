//
//  TangemCheckmarkV2Demo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemCheckmarkV2DemoViewModel: ObservableObject, Identifiable {}

struct TangemCheckmarkV2DemoView: View {
    @ObservedObject var viewModel: TangemCheckmarkV2DemoViewModel

    var body: some View {
        TangemCheckmarkV2Showcase()
            .navigationBarTitle(Text("TangemCheckmarkV2"))
    }
}
