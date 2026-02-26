//
//  TangemDotPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Previews

#if DEBUG

private typealias _Dot = TangemDot

// MARK: - Interactive Demo View

private struct DotDemoView: View {
    @State private var size: _Dot.Size = .x2
    @State private var selected: Bool = true

    var body: some View {
        VStack(spacing: 16) {
            pickerSection

            Spacer()

            dotPreview

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }

    private var pickerSection: some View {
        VStack(spacing: 8) {
            Picker("Size", selection: $size) {
                Text("x1").tag(_Dot.Size.x1)
                Text("x1.5").tag(_Dot.Size.x1_5)
                Text("x2").tag(_Dot.Size.x2)
            }
            .pickerStyle(.segmented)

            Toggle("Selected", isOn: $selected)
        }
    }

    private var dotPreview: some View {
        _Dot(selected: selected, size: size)
    }
}

// MARK: - Size Comparison

private struct DotSizeComparisonView: View {
    let sizes: [_Dot.Size] = [.x1, .x1_5, .x2]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sizes, id: \.self) { size in
                HStack(spacing: 12) {
                    Text(sizeName(size))
                        .frame(width: 40, alignment: .leading)

                    _Dot(selected: true, size: size)

                    _Dot(selected: false, size: size)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.2))
    }

    private func sizeName(_ size: _Dot.Size) -> String {
        switch size {
        case .x1: "x1"
        case .x1_5: "x1.5"
        case .x2: "x2"
        }
    }
}

#Preview("Interactive Demo") {
    DotDemoView()
}

#Preview("Dark Mode") {
    DotDemoView()
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type - Large") {
    DotSizeComparisonView()
        .dynamicTypeSize(.xxxLarge)
}

#Preview("Dynamic Type - Small") {
    DotSizeComparisonView()
        .dynamicTypeSize(.xSmall)
}

#endif
