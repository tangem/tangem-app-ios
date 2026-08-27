//
//  UtilGraphShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Sample data

private enum GraphSample {
    static let rising: [Double] = [2, 4, 3, 5, 6, 5.5, 8, 9]
    static let flat: [Double] = [5, 5.2, 4.9, 5.1, 5, 5.05, 4.95, 5]
    static let falling: [Double] = [9, 7, 8, 5, 6, 4, 3, 2]

    static func values(for direction: UtilGraph.Direction) -> [Double] {
        switch direction {
        case .positive: rising
        case .neutral: flat
        case .negative: falling
        }
    }
}

// MARK: - Showcase

public struct UtilGraphShowcase: View {
    @State private var direction: UtilGraph.Direction = .positive
    @State private var isLoading = false
    @State private var isDarkMode = false
    @State private var width: CGFloat = 48
    @State private var height: CGFloat = 32

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            previewArea
                .environment(\.colorScheme, isDarkMode ? .dark : .light)

            controls
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Color.bgPrimary)
    }

    private var previewArea: some View {
        UtilGraph(values: GraphSample.values(for: direction))
            .direction(direction)
            .isLoading(isLoading)
            .frame(width: width, height: height)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(DesignSystem.Color.bgSecondary)
    }

    private var controls: some View {
        ScrollView {
            VStack(spacing: 12) {
                Picker("Direction", selection: $direction) {
                    Text("positive").tag(UtilGraph.Direction.positive)
                    Text("neutral").tag(UtilGraph.Direction.neutral)
                    Text("negative").tag(UtilGraph.Direction.negative)
                }
                .pickerStyle(.segmented)

                Toggle("Loading", isOn: $isLoading)
                Toggle("Dark mode", isOn: $isDarkMode)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Width: \(Int(width))").font(.caption)
                    Slider(value: $width, in: 16 ... 320, step: 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Height: \(Int(height))").font(.caption)
                    Slider(value: $height, in: 16 ... 120, step: 1)
                }
            }
            .padding()
        }
    }
}
