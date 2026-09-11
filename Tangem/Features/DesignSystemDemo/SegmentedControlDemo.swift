//
//  SegmentedControlDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

final class SegmentedControlDemoViewModel: ObservableObject, Identifiable {}

struct SegmentedControlDemoView: View {
    @ObservedObject var viewModel: SegmentedControlDemoViewModel

    var body: some View {
        SegmentedControlShowcase()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.Color.bgPrimary)
    }
}
