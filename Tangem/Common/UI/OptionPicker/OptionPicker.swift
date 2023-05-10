//
//  OptionPicker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct OptionPicker<Content: View, Label: View, Option: Hashable & Identifiable>: View {
    @Binding private var selection: Option
    private let options: [Option]
    private let label: () -> Label
    private let content: (Option) -> Content

    public init(
        selection: Binding<Option>,
        options: [Option],
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping (Option) -> Content
    ) {
        _selection = selection
        self.options = options
        self.label = label
        self.content = content
    }

    var body: some View {
        label()
            .overlay(
                Menu {
                    Picker(selection: $selection, label: EmptyView()) {
                        ForEach(options) { action in
                            content(action)
                                .tag(action)
                        }
                    }
                    .labelsHidden()
                } label: {
                    Color.clear
                }
            )
    }
}
