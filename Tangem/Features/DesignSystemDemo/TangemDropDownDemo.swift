//
//  TangemDropDownDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemDropDownDemoViewModel: ObservableObject, Identifiable {}

struct TangemDropDownDemoView: View {
    @ObservedObject var viewModel: TangemDropDownDemoViewModel

    var body: some View {
        TangemDropDownShowcase()
            .navigationBarTitle(Text("TangemDropDown"))
    }
}
