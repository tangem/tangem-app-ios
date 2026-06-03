//
//  PeekingCarouselView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// Horizontal carousel with paging snap and adjacent-card peek, two-way bound to `selectedID`.
/// Caller must populate `items` and `selectedID` synchronously before rendering — `.scrollPosition(id:)`
/// alone doesn't honour its binding's initial value, so initial positioning is enforced by an
/// `.onAppear` `proxy.scrollTo` inside a `disablesAnimations` transaction, behind an opacity gate.
@available(iOS 17.0, *)
struct PeekingCarouselView<Item: Identifiable, Content: View>: View where Item.ID: Hashable {
    let items: [Item]
    @Binding var selectedID: Item.ID?
    var configuration: Configuration = .init()
    @ViewBuilder let content: (Item) -> Content

    struct Configuration {
        var peek: CGFloat = 12
        var spacing: CGFloat = 10

        var sidePadding: CGFloat { peek + spacing }
    }

    @State private var scrollID: Item.ID?
    @State private var didLandInitialScroll: Bool = false

    init(
        items: [Item],
        selectedID: Binding<Item.ID?>,
        configuration: Configuration = .init(),
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        _selectedID = selectedID
        self.configuration = configuration
        self.content = content
        _scrollID = State(initialValue: selectedID.wrappedValue)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: configuration.spacing) {
                    ForEach(items) { item in
                        content(item)
                            .containerRelativeFrame(.horizontal)
                            .id(item.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollID, anchor: .center)
            .scrollClipDisabled()
            .contentMargins(.horizontal, configuration.sidePadding, for: .scrollContent)
            .opacity(didLandInitialScroll ? 1 : 0)
            .animation(nil, value: didLandInitialScroll)
            .onChange(of: scrollID) { _, new in
                guard selectedID != new else { return }
                selectedID = new
            }
            .onChange(of: selectedID) { _, new in
                guard scrollID != new else { return }
                scrollID = new
            }
            .onAppear {
                guard let target = scrollID else {
                    didLandInitialScroll = true
                    return
                }
                DispatchQueue.main.async {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        proxy.scrollTo(target, anchor: .center)
                        didLandInitialScroll = true
                    }
                }
            }
        }
    }
}
