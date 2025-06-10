//
//  FloatingSheetRegisterer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct FloatingSheetRegisterer<SheetContentViewModel: FloatingSheetContentViewModel, SheetContent: View>: View {
    let type: SheetContentViewModel.Type
    let viewBuilder: (SheetContentViewModel) -> SheetContent

    @Environment(\.floatingSheetRegistry) private var registry: FloatingSheetRegistry

    var body: some View {
        Color.clear
            .onAppear {
                registry.register(type, viewBuilder: viewBuilder)
            }
    }
}
