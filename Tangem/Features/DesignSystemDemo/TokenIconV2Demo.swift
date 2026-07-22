//
//  TokenIconV2Demo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TokenIconV2DemoViewModel: ObservableObject, Identifiable {}

struct TokenIconV2DemoView: View {
    @ObservedObject var viewModel: TokenIconV2DemoViewModel

    var body: some View {
        TokenIconV2Showcase()
            .navigationBarTitle(Text("TokenIconV2"))
    }
}
