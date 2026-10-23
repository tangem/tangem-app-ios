//
//  TabNavigation.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUIUtils

public struct TabNavigation<Data>: View, Setupable
    where Data: RandomAccessCollection, Data.Element: TabNavigationItem {
    private let data: Data
    @Binding private var selection: Data.Element

    private var variant: Variant = .material
    private var isScrollable = false
    private var isLoading = false
    private var isHapticFeedbackEnabled = false
    private var accessibilityIdentifierFactory: ((Data.Element) -> String?)?

    @ScaledMetric private var spacing: CGFloat = Constants.interItemSpacing
    @Namespace private var pillNamespace

    public init(data: Data, selection: Binding<Data.Element>) {
        assert(data.count >= Constants.minimumTabCount, "TabNavigation is designed for at least two tabs")
        self.data = data
        _selection = selection
    }

    public var body: some View {
        if isScrollable {
            ScrollView(.horizontal, showsIndicators: false) {
                row.padding(.horizontal, Constants.contentHorizontalPadding)
            }
            .modifier(DisableScrollClipIfAvailable())
        } else {
            row
                .padding(.horizontal, Constants.contentHorizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var row: some View {
        HStack(spacing: spacing) {
            if isLoading {
                ForEach(0 ..< placeholderCount, id: \.self) { _ in
                    TabItemPlaceholder()
                        .transition(.opacity)
                }
            } else {
                ForEach(data) { item in
                    TabItemView(
                        item: item,
                        isSelected: item.id == selection.id,
                        onTap: {
                            if isHapticFeedbackEnabled, item.id != selection.id {
                                FeedbackGenerator.selection()
                            }

                            selection = item
                        }
                    )
                    .background {
                        if item.id == selection.id {
                            TabSelectionPill(variant: variant)
                                .matchedGeometryEffect(id: Constants.pillMatchID, in: pillNamespace)
                                .modifier(
                                    SelectionPillScale(
                                        trigger: selection.id,
                                        peakScaleX: Constants.pillPeakScale,
                                        phaseDuration: Constants.pillScalePhaseDuration
                                    )
                                )
                        }
                    }
                    .accessibilityIdentifier(accessibilityIdentifierFactory?(item))
                    .id(item.id)
                    .transition(.opacity)
                }
            }
        }
        .environment(\.isShimmerActive, isLoading)
        .animation(Constants.selectionAnimation, value: selection.id)
        .animation(Constants.loadingAnimation, value: isLoading)
    }

    private var placeholderCount: Int {
        max(data.count, 1)
    }
}

// MARK: - Setupable Modifiers

public extension TabNavigation {
    func variant(_ variant: Variant) -> Self {
        map { $0.variant = variant }
    }

    func scrollable(_ value: Bool = true) -> Self {
        map { $0.isScrollable = value }
    }

    func loading(_ value: Bool) -> Self {
        map { $0.isLoading = value }
    }

    func hapticFeedback(_ value: Bool = true) -> Self {
        map { $0.isHapticFeedbackEnabled = value }
    }

    func accessibilityIdentifier(factory: @escaping (Data.Element) -> String?) -> Self {
        map { $0.accessibilityIdentifierFactory = factory }
    }
}

// MARK: - Constants

private enum Constants {
    static let minimumTabCount = 2
    static let interItemSpacing: CGFloat = 4
    static let contentHorizontalPadding: CGFloat = 16
    static let pillMatchID = "TabNavigationSelectionPill"
    static let pillPeakScale: CGFloat = 1.1
    static let pillScalePhaseDuration: TimeInterval = 0.2
    static let selectionAnimation: Animation = .timingCurve(0.8, 0, 0.4, 1.2, duration: 0.4)
    static let loadingAnimation: Animation = .easeInOut(duration: 0.2)
}
