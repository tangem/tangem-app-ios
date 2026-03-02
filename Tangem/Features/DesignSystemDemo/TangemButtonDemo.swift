//
//  TangemButtonDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemButtonDemoViewModel: ObservableObject, Identifiable {}

struct TangemButtonDemoView: View {
    @ObservedObject var viewModel: TangemButtonDemoViewModel

    var body: some View {
        TangemButtonShowcase()
            .navigationBarTitle(Text("TangemButton"))
    }
}
