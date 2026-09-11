//
//  ShtorkaDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class ShtorkaDemoViewModel: ObservableObject, Identifiable {}

struct ShtorkaDemoView: View {
    @ObservedObject var viewModel: ShtorkaDemoViewModel

    var body: some View {
        ShtorkaShowcase()
            .navigationBarTitle(Text("Shtorka"))
    }
}
