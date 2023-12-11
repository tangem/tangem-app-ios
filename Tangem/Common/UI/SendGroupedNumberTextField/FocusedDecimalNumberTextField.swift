//
//  FocusedDecimalNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

/// It same as`DecimalNumberTextField` but with support focus state and toolbar buttons
@available(iOS 15.0, *)
struct FocusedDecimalNumberTextField<ToolbarButton: View>: View {
    @Binding private var decimalValue: DecimalNumberTextField.DecimalValue?
    @FocusState private var isInputActive: Bool
    private var maximumFractionDigits: Int
    private let font: Font

    @State private var configuredTextFields: Set<ObjectIdentifier> = []

    private let toolbarButton: () -> ToolbarButton

    init(
        decimalValue: Binding<DecimalNumberTextField.DecimalValue?>,
        maximumFractionDigits: Int,
        font: Font,
        @ViewBuilder toolbarButton: @escaping () -> ToolbarButton
    ) {
        _decimalValue = decimalValue
        self.maximumFractionDigits = maximumFractionDigits
        self.font = font
        self.toolbarButton = toolbarButton
    }

    var body: some View {
        DecimalNumberTextField(
            decimalValue: $decimalValue,
            decimalNumberFormatter: DecimalNumberFormatter(maximumFractionDigits: maximumFractionDigits),
            font: font
        )
        .maximumFractionDigits(maximumFractionDigits)
        .focused($isInputActive)
        .onAppear {
            isInputActive = true
        }
        .introspect { (instance: UITextField) in
            let identifier = ObjectIdentifier(instance)

            if configuredTextFields.contains(identifier) {
                return
            }

            /// Prevents errors like "Modifying state during view update, this will cause undefined behavior."
            DispatchQueue.main.async {
                configuredTextFields.insert(identifier)
            }
            instance.inputAccessoryView = Self.makeInputAccessoryView()
        }
    }
}

// MARK: - Factory methods

@available(iOS 15.0, *)
private extension FocusedDecimalNumberTextField {
    static func makeInputAccessoryView() -> some UIView {
        let image = Assets.hideKeyboard.uiImage.withRenderingMode(.alwaysTemplate)
        let temp = UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
        temp.tintColor = UIColor(named: "IconPrimary1")

        let toolBar = UIToolbar()
        toolBar.items = [
            UIBarButtonItem(title: Localization.sendMaxAmountLabel),
            UIBarButtonItem(systemItem: .flexibleSpace),
            temp,
        ]
        toolBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return toolBar
    }
}

extension View {
    func introspect<T>(_ configuration: @escaping (_ instance: T) -> Void) -> some View {
        background(Introspector(configuration: configuration))
    }
}

// MARK: - Setupable

@available(iOS 15.0, *)
extension FocusedDecimalNumberTextField: Setupable {
    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.maximumFractionDigits = digits }
    }
}

struct FocusedNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: DecimalNumberTextField.DecimalValue?

    static var previews: some View {
        if #available(iOS 15.0, *) {
            FocusedDecimalNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: 8, font: Fonts.Regular.title1) {}
        }
    }
}

struct Introspector<T>: UIViewRepresentable {
    var configuration: ((_ instance: T) -> Void)?

    func makeUIView(context: Context) -> UIView {
        // No need to apply configuration here since `UIView` instance hasn't added yet to the view hierarchy
        return UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        applyConfiguration(with: uiView)
    }

    private func applyConfiguration(with uiView: UIView?) {
        var currentUIView = uiView

        while let nextUIView = currentUIView {
            if let targetView: T = searchInSubviews(of: nextUIView), let configuration = configuration {
                configuration(targetView)
                break
            }
            currentUIView = nextUIView.superview
        }
    }

    private func searchInSubviews(of view: UIView) -> T? {
        if let targetView = view as? T {
            return targetView
        }

        for subview in view.subviews {
            if let targetView: T = searchInSubviews(of: subview) {
                return targetView
            }
        }

        return nil
    }
}
