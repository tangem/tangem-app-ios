//
//  TangemSegmentedPickerDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemSegmentedPickerDemoModel: ObservableObject, Identifiable {}

struct TangemSegmentedPickerDemo: View {
    @ObservedObject var viewModel: TangemSegmentedPickerDemoModel

    var body: some View {
        TangemSegmentedPickerShowcase()
            .navigationBarTitle(Text("TangemSegmentedPicker"))
    }
}
