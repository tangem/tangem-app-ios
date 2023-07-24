//
//  View+onTouchesBegan.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    typealias OnTouchesBegan = (_ location: CGPoint) -> Void

    @ViewBuilder
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "Replace with native 'SpatialTapGesture'")
    func onTouchesBegan(_ action: @escaping OnTouchesBegan) -> some View {
        overlay(TouchesBeganInterceptor(onTouchesBegan: action))
    }
}

// MARK: - Private implementation

private struct TouchesBeganInterceptor: UIViewRepresentable {
    private final class InterceptorView: UIView {
        var onTouchesBegan: OnTouchesBegan?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            defer { super.touchesBegan(touches, with: event) }

            guard let touch = touches.first else { return }

            onTouchesBegan?(touch.location(in: self))
        }
    }

    let onTouchesBegan: OnTouchesBegan

    func makeUIView(context: Context) -> UIView {
        let interceptorView = InterceptorView()
        interceptorView.onTouchesBegan = onTouchesBegan

        return interceptorView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
