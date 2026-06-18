//
//  TangemSnackbarDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemSnackbarDemoViewModel: ObservableObject, Identifiable {}

struct TangemSnackbarDemoView: View {
    @ObservedObject var viewModel: TangemSnackbarDemoViewModel

    var body: some View {
        TangemSnackbarShowcase()
            .navigationBarTitle(Text("TangemSnackbar"))
    }
}
