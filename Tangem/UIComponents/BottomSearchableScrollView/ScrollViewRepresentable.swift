//
//  ScrollViewRepresentable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ScrollViewRepresentable: UIViewRepresentable {
    public let onChanged: (ClearDragGestureView.Value) -> Void
    public let onEnded: (ClearDragGestureView.Value) -> Void

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

extension ScrollViewRepresentable {
    class Coordinator: NSObject, UIScrollViewDelegate {
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            print("scrollView", scrollView.contentOffset)
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            print(#function)
        }
    }
}
