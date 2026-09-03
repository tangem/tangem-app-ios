//
//  StatusScreenDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class StatusScreenDemoViewModel: ObservableObject, Identifiable {}

struct StatusScreenDemoView: View {
    @ObservedObject var viewModel: StatusScreenDemoViewModel

    var body: some View {
        StatusScreenShowcase()
            .navigationBarTitle(Text("StatusScreen"))
    }
}
