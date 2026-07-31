//
//  UtilGraphDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class UtilGraphDemoViewModel: ObservableObject, Identifiable {}

struct UtilGraphDemoView: View {
    @ObservedObject var viewModel: UtilGraphDemoViewModel

    var body: some View {
        UtilGraphShowcase()
            .navigationBarTitle(Text("UtilGraph"))
    }
}
