//
//  ActivityIndicatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

public struct IndicatorSettings {
    let style: UIActivityIndicatorView.Style
    let color: UIColor

    public static let `default` = IndicatorSettings(style: .medium, color: .white)

    public init(style: UIActivityIndicatorView.Style, color: UIColor) {
        self.style = style
        self.color = color
    }
}

public struct ActivityIndicatorView: UIViewRepresentable {
    var isAnimating: Bool
    var style: UIActivityIndicatorView.Style
    var color: UIColor

    public init(isAnimating: Bool = true, style: UIActivityIndicatorView.Style = .medium, color: UIColor = .white) {
        self.isAnimating = isAnimating
        self.style = style
        self.color = color
    }

    public init(settings: IndicatorSettings) {
        isAnimating = true
        style = settings.style
        color = settings.color
    }

    public func makeUIView(context: UIViewRepresentableContext<ActivityIndicatorView>) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: style)
        indicator.color = color
        return indicator
    }

    public func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicatorView>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
