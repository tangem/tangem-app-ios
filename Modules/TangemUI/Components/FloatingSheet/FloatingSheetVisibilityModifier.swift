//
//  FloatingSheetVisibilityModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct FloatingSheetVisibilityModifier<SheetContentViewModel: FloatingSheetContentViewModel>: ViewModifier {
    private let visibility: FloatingSheetVisibility = .shared

    let type: SheetContentViewModel.Type

    func body(content: Content) -> some View {
        content
            .onAppear { visibility.appeared(type) }
            .onDisappear { visibility.disappeared(type) }
    }
}
