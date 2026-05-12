//
//  TangemBadgeV2Demo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemBadgeV2DemoViewModel: ObservableObject, Identifiable {}

struct TangemBadgeV2DemoView: View {
    @ObservedObject var viewModel: TangemBadgeV2DemoViewModel

    var body: some View {
        TangemBadgeV2Showcase()
            .navigationBarTitle(Text("TangemBadgeV2"))
    }
}
