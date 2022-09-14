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
    case changeHeight(byValue: CGFloat)
}

protocol ResizableSheetView: View {
    typealias ResizeCallback = ((ResizeSheetAction) -> ())
    func setResizeCallback(_ callback: @escaping ResizeCallback)
}

struct BottomSheetEmptyView: ResizableSheetView {
    var body: some View {
        EmptyView()
    }

    func setResizeCallback(_ callback: @escaping ResizeCallback) { }
}
