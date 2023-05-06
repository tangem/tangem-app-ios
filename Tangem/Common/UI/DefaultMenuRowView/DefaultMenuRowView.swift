//
//  DefaultMenuRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct DefaultMenuRowView<Action: DefaultMenuRowViewModelAction>: View {
    private let viewModel: DefaultMenuRowViewModel<Action>
    @Binding private var selection: Action

    init(viewModel: DefaultMenuRowViewModel<Action>, selection: Binding<Action>) {
        self.viewModel = viewModel
        _selection = selection
    }

    var body: some View {
        HStack {
            Text(viewModel.title)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)

            Spacer()

            menuView
        }
        .padding(.vertical, 14)
    }

    private var menuView: some View {
        Menu {
            ForEach(viewModel.actions) { action in
                Button {
                    selection = action
                } label: {
                    Label {
                        Text(action.title)
                            .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    } icon: {
                        if selection == action {
                            Assets.check.image
                                .renderingMode(.template)
                                .foregroundColor(Colors.Icon.primary1)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } label: {
            HStack(spacing: 0) {
                Text(selection.title)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)

                Assets.chevronDownMaxi.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(Colors.Icon.primary1)
            }
        }
        .animation(.none)
    }
}

struct DefaultMenuRowView_Preview: PreviewProvider {
    struct PreviewView: View {
        @State private var selectedAction: ActionType = .unlimited

        var viewModel: DefaultMenuRowViewModel<ActionType> {
            DefaultMenuRowViewModel(
                title: "Select action",
                actions: ActionType.allCases
            )
        }

        var body: some View {
            DefaultMenuRowView(viewModel: viewModel, selection: $selectedAction)
                .padding(.horizontal, 16)
                .background(Colors.Background.secondary)
        }

        enum ActionType: DefaultMenuRowViewModelAction, CaseIterable {
            case current
            case unlimited

            var id: Int { hashValue }

            var title: String {
                switch self {
                case .current:
                    return "Current transaction"
                case .unlimited:
                    return "Unlimited"
                }
            }
        }
    }

    static var previews: some View {
        PreviewView()
            .preferredColorScheme(.light)

        PreviewView()
            .preferredColorScheme(.dark)
    }
}
