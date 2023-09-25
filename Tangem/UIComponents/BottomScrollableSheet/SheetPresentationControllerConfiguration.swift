//
//  PresentationBackgroundInteractionViewController.swift
//  BottomSheetTest
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import UIKit
import SwiftUI

@available(
    iOS,
    introduced: 15.0,
    obsoleted: 16.4,
    message: "Use native methods to configure 'UISheetPresentationController' in SwiftUI environment instead"
)
extension View {
    func configureSheetPresentationController(
        _ configuration: @escaping SheetPresentationControllerConfigurationModifier.Configuration
    ) -> some View {
        modifier(SheetPresentationControllerConfigurationModifier(configuration: configuration))
    }
}

@available(
    iOS,
    introduced: 15.0,
    obsoleted: 16.4,
    message: "Use native methods to configure 'UISheetPresentationController' in SwiftUI environment instead"
)
struct SheetPresentationControllerConfigurationModifier: ViewModifier {
    typealias Configuration = (_ controller: UISheetPresentationController) -> Void

    let configuration: Configuration

    func body(content: Content) -> some View {
        content.background(SheetPresentationControllerConfigurationViewControllerHolder(configuration: configuration))
    }
}

@available(
    iOS,
    introduced: 15.0,
    obsoleted: 16.4,
    message: "Use native methods to configure 'UISheetPresentationController' in SwiftUI environment instead"
)
private final class SheetPresentationControllerConfigurationViewController: UIViewController {
    var configuration: SheetPresentationControllerConfigurationModifier.Configuration?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSheetPresentationController()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureSheetPresentationController()
    }

    private func configureSheetPresentationController() {
        guard
            let configuration = configuration,
            let sheetPresentationController = sheetPresentationController
        else {
            return
        }

        configuration(sheetPresentationController)
    }
}

@available(
    iOS,
    introduced: 15.0,
    obsoleted: 16.4,
    message: "Use native methods to configure 'UISheetPresentationController' in SwiftUI environment instead"
)
private struct SheetPresentationControllerConfigurationViewControllerHolder: UIViewControllerRepresentable {
    let configuration: SheetPresentationControllerConfigurationModifier.Configuration

    func makeUIViewController(context: Context) -> SheetPresentationControllerConfigurationViewController {
        let uiViewController = SheetPresentationControllerConfigurationViewController()
        uiViewController.configuration = configuration
        return uiViewController
    }

    func updateUIViewController(_ uiViewController: SheetPresentationControllerConfigurationViewController, context: Context) {
        uiViewController.configuration = configuration
        uiViewController.view.setNeedsLayout()
    }
}
