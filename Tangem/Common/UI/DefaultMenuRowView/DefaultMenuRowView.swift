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
                Button(action.title) {
                    withAnimation(nil) {
                        selection = action
                    }
                }
                .font(Fonts.Regular.body)
                .foregroundColor(Colors.Text.primary1)
                .buttonStyle(.borderless)
                //                Text(action.title)
                //                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
//                .tag(action)
            }
        } label: {
            HStack(spacing: 0) {
                Text(selection.title)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)

                Assets.chevronDownMaxi.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.primary1)
            }
//            .animation(nil)
        }
        .menuStyle(MyMenuStyle())
        .frame(idealWidth: 24)
    }

    private var pickerView: some View {
        Picker(selection: $selection) {
            ForEach(viewModel.actions) { action in
                Text(action.title)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    .tag(action)
            }
        } label: {
            Text(selection.title)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .lineLimit(1)
                .animation(nil, value: selection)
        }
        .pickerStyle(.menu)
        .frame(height: 24)
//        .border(Color.red)
        .animation(nil, value: selection)
    }
}

struct MyMenuStyle: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .animation(nil)
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
