//
//  NavigationBarButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization

/// A button used as a replacement for a system navigation bar button.
///
/// On iOS 26, it matches look and feel of system ``NavigationStack`` back / close toolbar buttons.
///
/// On earlier iOS versions, an icon with a round background is used.
/// - SeeAlso: Prefer using ``NavigationToolbarButton`` when you need back button inside ``View.toolbar(content:)`` to avoid glass effect overlap.
public struct NavigationBarButton: View {
    private let sfSymbol: String
    private let iconAsset: ImageType
    private let action: () -> Void

    /// Creates a navigation bar button.
    /// - Parameters:
    ///   - sfSymbol: The name of the system symbol image. Use the SF Symbols app to look up the names of system symbol images.
    ///   - iconAsset: The icon used for 18 and older iOS versions.
    ///   - action: The action to perform when the user triggers the button.
    init(sfSymbol: String, iconAsset: ImageType, action: @escaping () -> Void) {
        self.sfSymbol = sfSymbol
        self.iconAsset = iconAsset
        self.action = action
    }

    public var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            systemLabelButton
        } else {
            circleIconButton
        }
        #else
        circleIconButton
        #endif
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, *)
    private var systemLabelButton: some View {
        Button(action: action) {
            Image(systemName: sfSymbol)
                .foregroundStyle(Colors.Text.primary1)
                .font(.title2)
                .fontWeight(.medium)
                .frame(width: 20, height: 20)
                .padding(12)
        }
        .glassEffect(.regular.interactive(), in: .circle)
    }
    #endif

    private var circleIconButton: some View {
        Button(action: action) {
            iconAsset.image
                .resizable()
                .renderingMode(.template)
                .frame(width: 20, height: 20)
                .foregroundStyle(Colors.Icon.informative)
                .padding(4)
                .background {
                    Circle()
                        .fill(Colors.Button.secondary)
                }
                .contentShape(.rect)
        }
    }
}

// MARK: - Factory methods

public extension NavigationBarButton {
    static func back(action: @escaping () -> Void) -> some View {
        navigationBarButton(for: .back, action: action)
    }

    static func close(action: @escaping () -> Void) -> some View {
        navigationBarButton(for: .close, action: action)
    }

    private static func navigationBarButton(for role: NavigationBarButtonRole, action: @escaping () -> Void) -> some View {
        NavigationBarButton(sfSymbol: role.sfSymbol, iconAsset: role.iconAsset, action: action)
            .accessibilityIdentifier(role.accessibilityIdentifier)
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview("", traits: .fixedLayout(width: 200, height: 100)) {
    @Previewable @State var path = NavigationPath([1, 2])
    let colors: [Color] = [.orange, .black, .gray, .red, .green, .yellow, .cyan, .indigo, .pink, .purple]

    NavigationStack(path: $path) {
        VStack {
            NavigationLink("Screen 1", value: 1)
            NavigationLink("Screen 2", value: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Root screen")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Int.self) { number in
            VStack(alignment: .leading) {
                ScrollView {
                    ForEach(1 ... 50, id: \.self) { _ in
                        HStack {
                            Text("Lorem ipsum")
                                .foregroundStyle(colors.randomElement()!)
                            Spacer()
                            Text(" dolor sit amet")
                                .foregroundStyle(colors.randomElement()!)
                        }
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .padding(.horizontal, 18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer()

                NavigationLink("Open next screen \(number + 1)", value: number + 1)
                    .padding()

                Spacer()
            }
            .overlay(alignment: .top) {
                HStack(spacing: 12) {
                    NavigationBarButton.back(action: { path.removeLast() })
                    NavigationBarButton.back(action: { path.removeLast() })

                    Spacer()

                    NavigationBarButton.close(action: { path.removeLast() })
                    NavigationBarButton.close(action: { path.removeLast() })
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .navigationTitle("Screen \(number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                NavigationToolbarButton.back(
                    placement: .topBarLeading,
                    action: { path.removeLast() }
                )

                NavigationToolbarButton.close(
                    placement: .topBarTrailing,
                    action: { path.removeLast() }
                )

                #if compiler(>=6.2)
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .close) {}
                    }
                }
                #endif
            }
        }
    }
}
