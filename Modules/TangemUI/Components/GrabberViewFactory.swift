//
//  GrabberViewFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccessibilityIdentifiers

public struct GrabberViewFactory {
    public init() {}

    public func makeUIKitView() -> UIView {
        let grabberView = UIView()
        grabberView.translatesAutoresizingMaskIntoConstraints = false
        grabberView.backgroundColor = .iconInactive
        grabberView.layer.cornerCurve = .continuous
        grabberView.layer.cornerRadius = min(
            Constants.grabberSize.height,
            Constants.grabberSize.width
        ) / 2.0

        let grabberViewContainer = UIView()
        grabberViewContainer.translatesAutoresizingMaskIntoConstraints = false
        grabberViewContainer.isUserInteractionEnabled = false
        grabberViewContainer.accessibilityIdentifier = CommonUIAccessibilityIdentifiers.grabber
        grabberViewContainer.addSubview(grabberView)

        NSLayoutConstraint.activate([
            grabberView.heightAnchor.constraint(equalToConstant: Constants.grabberSize.height),
            grabberView.widthAnchor.constraint(equalToConstant: Constants.grabberSize.width),
            grabberView.leadingAnchor.constraint(equalTo: grabberViewContainer.leadingAnchor),
            grabberView.trailingAnchor.constraint(equalTo: grabberViewContainer.trailingAnchor),
            grabberView.bottomAnchor.constraint(equalTo: grabberViewContainer.bottomAnchor),
            grabberView.topAnchor.constraint(equalTo: grabberViewContainer.topAnchor, constant: Constants.topInset),
        ])

        return grabberViewContainer
    }

    @ViewBuilder
    public func makeSwiftUIView() -> some View {
        Capsule(style: .continuous)
            .fill(Colors.Icon.inactive)
            .frame(size: Constants.grabberSize)
            .padding(.vertical, Constants.topInset)
            .infinityFrame(axis: .horizontal)
            .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.grabber)
    }
}

// MARK: - Constants

private extension GrabberViewFactory {
    enum Constants {
        static let topInset = 8.0
        static var grabberSize: CGSize { CGSize(width: 32.0, height: 4.0) }
    }
}
