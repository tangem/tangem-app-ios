//
//  SelectableSection.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets
import TangemFoundation

public protocol SelectableSectionRow: View {
    var isSelected: Bool { get }
}

public struct SelectableSection<Model: Identifiable, Content: SelectableSectionRow>: View {
    private let models: [Model]
    private let content: (Model) -> Content
    private var areSeparatorsEnabled: Bool = true

    private var separatorPadding = SeparatorPadding()

    public init(
        _ models: [Model],
        @ViewBuilder content: @escaping (Model) -> Content
    ) {
        self.models = models
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(models.indexed(), id: \.1.id) { index, model in
                let nextIsSelected = models[safe: index + 1].map { content($0).isSelected } ?? false
                let rowView = content(model)
                let currentIsSelected = rowView.isSelected
                let shouldShowSeparator = !nextIsSelected && !rowView.isSelected && models.last?.id != model.id

                rowView
                    .onChange(of: rowView.isSelected) { newValue in
                        newValue ? FeedbackGenerator.selectionChanged() : ()
                    }
                    .overlay(alignment: .bottom) {
                        if currentIsSelected {
                            SelectionOverlay()
                        } else if shouldShowSeparator, areSeparatorsEnabled {
                            Separator(color: Colors.Stroke.primary)
                                .padding(.leading, separatorPadding.leading)
                                .padding(.trailing, separatorPadding.trailing)
                        }
                    }
            }
        }
    }
}

// MARK: - Setupable

extension SelectableSection: Setupable {
    public func separatorPadding(_ padding: SeparatorPadding) -> Self {
        map { $0.separatorPadding = padding }
    }

    public func enableSeparators(_ areEnabled: Bool) -> Self {
        map { $0.areSeparatorsEnabled = areEnabled }
    }
}

public extension SelectableSection {
    struct SeparatorPadding {
        let leading: CGFloat
        let trailing: CGFloat

        public init(leading: CGFloat = 14, trailing: CGFloat = 14) {
            self.leading = leading
            self.trailing = trailing
        }
    }
}
