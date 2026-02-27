//
//  TangemMainActionButtonDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemMainActionButtonDemoViewModel: ObservableObject, Identifiable {}

struct TangemMainActionButtonDemoView: View {
    @ObservedObject var viewModel: TangemMainActionButtonDemoViewModel

    var body: some View {
        TangemMainActionButtonShowcase()
            .navigationBarTitle(Text("MainActionButton"))
    }
}
