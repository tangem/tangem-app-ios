//
//  DSShowcaseControls.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUIUtils

@MainActor
struct DSShowcaseControls {
    func picker<Value: CaseIterable & Hashable>(
        _ title: String,
        _ selection: Binding<Value>
    ) -> some View where Value.AllCases: RandomAccessCollection {
        picker(title, selection, options: Array(Value.allCases))
    }

    func picker<Value: Hashable>(
        _ title: String,
        _ selection: Binding<Value>,
        options: [Value],
        label: ((Value) -> String)? = nil
    ) -> some View {
        DSShowcaseRow(title) {
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(label?(option) ?? DSShowcaseLabel.text(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    func picker<Value: CaseIterable & Hashable>(
        _ title: String,
        _ selection: Binding<Value?>
    ) -> some View where Value.AllCases: RandomAccessCollection {
        picker(title, selection, options: [nil] + Value.allCases.map(Optional.some)) { value in
            value.map { DSShowcaseLabel.text($0) } ?? "none"
        }
    }

    func toggle(_ title: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            DSShowcaseRowTitle(title)
        }
    }

    func text(_ title: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            DSShowcaseRowTitle(title)
            TextField(title, text: text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
        }
    }

    func value<Value: BinaryFloatingPoint>(
        _ title: String,
        _ value: Binding<Value>,
        in range: ClosedRange<Value>,
        step: Value.Stride = 1
    ) -> some View where Value.Stride: BinaryFloatingPoint {
        VStack(alignment: .leading, spacing: 6) {
            DSShowcaseRow(title) {
                DSShowcaseReadout(String(format: "%.1f", Double(value.wrappedValue)))
            }
            Slider(value: value, in: range, step: step)
        }
    }

    func value(_ title: String, _ value: Binding<Int>, in range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            DSShowcaseRow(title) {
                DSShowcaseReadout("\(value.wrappedValue)")
            }
        }
    }

    func action(_ title: String, _ action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            Text(title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textAccentBlue)
        }
    }

    func readout(_ title: String, _ value: String) -> some View {
        DSShowcaseRow(title) {
            DSShowcaseReadout(value)
        }
    }

    func note(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum DSShowcaseLabel {
    static func text(_ value: some Any) -> String {
        String(describing: value)
    }
}

struct DSShowcaseRow<Accessory: View>: View {
    private let title: String
    private let accessory: Accessory

    init(_ title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: 12) {
            DSShowcaseRowTitle(title)
            Spacer(minLength: 0)
            accessory
        }
    }
}

struct DSShowcaseRowTitle: View {
    private let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
    }
}

private struct DSShowcaseReadout: View {
    private let value: String

    init(_ value: String) {
        self.value = value
    }

    var body: some View {
        Text(value)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            .monospacedDigit()
    }
}
#endif
