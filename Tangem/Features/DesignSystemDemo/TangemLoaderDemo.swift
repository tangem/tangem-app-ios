//
//  TangemLoaderDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemLoaderDemoViewModel: ObservableObject, Identifiable {}

struct TangemLoaderDemoView: View {
    @ObservedObject var viewModel: TangemLoaderDemoViewModel

    var body: some View {
        TangemLoaderShowcase()
            .navigationBarTitle(Text("TangemLoader"))
    }
}
