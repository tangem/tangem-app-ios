//
//  ResizableSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

enum ResizeSheetAction {
    case incrementSheetHeight(byValue: CGFloat)
    case decrementSheetHeight(byValue: CGFloat)
    case setNewSheetHeight(value: CGFloat)
}

protocol ResizableSheetView: View {
    func updateHeight(callback: @escaping ((ResizeSheetAction) -> ()))
}

struct BottomSheetEmptyView: ResizableSheetView {
    var body: some View {
        EmptyView()
    }

    func updateHeight(callback: @escaping ((ResizeSheetAction) -> ())) { }
}
