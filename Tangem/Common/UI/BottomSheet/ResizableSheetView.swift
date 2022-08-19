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
    var updateHeight: ((ResizeSheetAction) -> ())? { get set }
}

struct BottomSheetEmptyView: ResizableSheetView {
    var updateHeight: ((ResizeSheetAction) -> ())?

    var body: some View {
        EmptyView()
    }
}
