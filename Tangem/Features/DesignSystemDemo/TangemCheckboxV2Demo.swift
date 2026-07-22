//
//  TangemCheckboxV2Demo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemCheckboxV2DemoViewModel: ObservableObject, Identifiable {}

struct TangemCheckboxV2DemoView: View {
    @ObservedObject var viewModel: TangemCheckboxV2DemoViewModel

    var body: some View {
        CheckboxShowcase()
            .navigationBarTitle(Text("Checkbox"))
    }
}
