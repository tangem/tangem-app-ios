//
//  ShtorkaShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct ShtorkaShowcase: View {
    @State private var isShtorkaPresented = true
    @State private var shtorkaSize: ShtorkaSize
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var path: [ShtorkaMockToken] = []
    @State private var selectedTab: ShtorkaMockTab = .crypto
    @State private var isModalPresented = false
    @State private var backdropItem: ShtorkaMockBackdropItem?
    @State private var isAlertPresented = false
    @State private var isDialogPresented = false
    @State private var isSheetPresented = false
    @State private var isCoverPresented = false
    @State private var legacySheetItem: ShtorkaMockLegacySheetItem?
    @State private var sheetItem: ShtorkaMockPresentedItem?
    @State private var coverItem: ShtorkaMockPresentedItem?
    @State private var alertItem: ShtorkaMockPresentedItem?

    public init(initialSize: ShtorkaSize = .collapsed) {
        _shtorkaSize = State(initialValue: initialSize)
    }

    public var body: some View {
        ShtorkaMockBackdrop(
            shtorkaSize: shtorkaSize,
            onRowTap: { index in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    isShtorkaPresented = false
                }
                backdropItem = ShtorkaMockBackdropItem(id: index)
            },
            onAlertTap: {
                isAlertPresented = true
            },
            onDialogTap: {
                isDialogPresented = true
            },
            onSheetTap: {
                isSheetPresented = true
            },
            onCoverTap: {
                isCoverPresented = true
            },
            onSheetItemTap: {
                sheetItem = ShtorkaMockPresentedItem(title: "Sheet presented by item")
            },
            onCoverItemTap: {
                coverItem = ShtorkaMockPresentedItem(title: "Cover presented by item")
            },
            onAlertItemTap: {
                alertItem = ShtorkaMockPresentedItem(title: "Alert presented by item")
            },
            onLegacySheetTap: {
                legacySheetItem = ShtorkaMockLegacySheetItem()
            },
            onToastTap: {
                Toast(view: SuccessToast(text: "Dummy toast raised from the root view"))
                    .present(layout: .top(padding: 14), type: .temporary())
            }
        )
        .fullScreenCover(item: $backdropItem, onDismiss: showShtorka) { item in
            ShtorkaMockBackdropDetail(index: item.id) {
                backdropItem = nil
            }
        }
        .shtorkaCompatibleAlert("Dummy alert", isPresented: $isAlertPresented, message: "An alert raised from the root view") {
            SwiftUI.Button("Cancel", role: .cancel) {}
            SwiftUI.Button("Confirm") {}
        }
        .shtorkaCompatibleConfirmationDialog(
            "Dummy confirmation dialog",
            isPresented: $isDialogPresented,
            titleVisibility: .visible,
            message: "A confirmation dialog raised from the root view"
        ) {
            SwiftUI.Button("Destructive action", role: .destructive) {}
            SwiftUI.Button("Regular action") {}
            SwiftUI.Button("Cancel", role: .cancel) {}
        }
        .shtorkaCompatibleSheet(isPresented: $isSheetPresented) { dummySheet }
        .shtorkaCompatibleFullScreenCover(isPresented: $isCoverPresented) { dummyCover }
        .shtorkaCompatibleSheet(item: $sheetItem) { item in
            presentedByItem(item) { sheetItem = nil }
                .presentationDetents([.medium])
        }
        .shtorkaCompatibleFullScreenCover(item: $coverItem) { item in
            presentedByItem(item) { coverItem = nil }
        }
        .shtorkaCompatibleAlert(item: $alertItem) { item in
            Alert(title: Text(item.title), dismissButton: .cancel(Text("OK")))
        }
        .bottomSheet(item: $legacySheetItem, backgroundColor: DesignSystem.Color.bgTertiary) { _ in
            ShtorkaMockLegacySheetContent {
                legacySheetItem = nil
            }
        }
        .shtorka(isPresented: $isShtorkaPresented, size: $shtorkaSize) {
            ShtorkaShowcaseSheet(
                shtorkaSize: $shtorkaSize,
                searchText: $searchText,
                isSearchActive: $isSearchActive,
                path: $path,
                selectedTab: $selectedTab,
                isModalPresented: $isModalPresented
            )
        }
        .onChange(of: shtorkaSize) { size in
            if size == .collapsed {
                path.removeAll()
                isSearchActive = false
            }
        }
        .onChange(of: isSearchActive) { isActive in
            if isActive {
                shtorkaSize = .full
            }
        }
        .onChange(of: selectedTab) { _ in
            shtorkaSize = .full
        }
        .onChange(of: path) { path in
            if !path.isEmpty, shtorkaSize != .full {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    shtorkaSize = .full
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func showShtorka() {
        isShtorkaPresented = true
    }

    private func presentedByItem(_ item: ShtorkaMockPresentedItem, onClose: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Text(item.title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            SwiftUI.Button("Close", action: onClose)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
    }

    private var dummySheet: some View {
        VStack(spacing: 16) {
            Text("Sheet presented from the root view")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            SwiftUI.Button("Close") { isSheetPresented = false }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
        .presentationDetents([.medium])
        .environment(\.colorScheme, .dark)
    }

    private var dummyCover: some View {
        VStack(spacing: 16) {
            Text("Full screen cover presented from the root view")
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)

            SwiftUI.Button("Close") { isCoverPresented = false }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
    }
}

private struct ShtorkaMockBackdropItem: Identifiable {
    let id: Int
}

struct ShtorkaMockPresentedItem: Identifiable {
    let id = UUID()
    let title: String
}

private struct ShtorkaMockLegacySheetItem: Identifiable {
    let id = "legacy-bottom-sheet"
}

private struct ShtorkaMockLegacySheetContent: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Legacy bottom sheet — a UIHostingController presented from the top view controller")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)

            SwiftUI.Button("Close", action: onClose)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .environment(\.colorScheme, .dark)
    }
}

private struct ShtorkaMockBackdropDetail: View {
    let index: Int
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Wallet row \(index)")
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            Text("Opened from the backdrop — the shtorka hides while this screen is open and comes back on close")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)

            SwiftUI.Button("Close", action: onClose)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
    }
}

private struct ShtorkaShowcaseSheet: View {
    @Binding var shtorkaSize: ShtorkaSize
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    @Binding var path: [ShtorkaMockToken]
    @Binding var selectedTab: ShtorkaMockTab
    @Binding var isModalPresented: Bool

    @State private var liveHeight: CGFloat = 0

    var body: some View {
        NavigationStack(path: $path) {
            content
                .readGeometry(\.size.height, bindTo: $liveHeight)
                .animation(.easeInOut(duration: 0.18), value: showsSearchRow)
                .navigationDestination(for: ShtorkaMockToken.self) {
                    ShtorkaMockTokenDetail(token: $0, isModalPresented: $isModalPresented)
                }
        }
        .sheet(isPresented: $isModalPresented) { modal }
        .environment(\.colorScheme, .dark)
    }

    private var showsSearchRow: Bool {
        if shtorkaSize == .collapsed {
            return true
        }

        return liveHeight > 0 && liveHeight < Constants.searchRowHeightLimit
    }

    private var modal: some View {
        VStack(spacing: 16) {
            Text("Feature sheet presented from the shtorka")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            SwiftUI.Button("Close") { isModalPresented = false }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
        .presentationDetents([.medium])
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var content: some View {
        if showsSearchRow {
            searchRow
                .transition(.opacity)
        } else {
            expandedContent
                .transition(.opacity)
        }
    }

    private var searchRow: some View {
        Search(text: $searchText, isActive: $isSearchActive)
            .placeholder("Crypto, stocks and more")
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var expandedContent: some View {
        VStack(spacing: 12) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .crypto:
                        ShtorkaMockBanner { isModalPresented = true }
                        ShtorkaMockMarketCap()
                        ShtorkaMockMarketPulse()
                    case .realAssets:
                        ShtorkaMockRealAssets()
                    case .earn:
                        ShtorkaMockEarn { isModalPresented = true }
                    case .predictions:
                        ShtorkaMockPredictions()
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
            .clipped()
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Search(text: $searchText, isActive: $isSearchActive)
                .placeholder("Crypto, stocks and more")
                .padding(.horizontal, 16)
                .padding(.top, 24)

            ShtorkaMockWidgetsRow()

            ShtorkaMockTabChips(selected: $selectedTab)

            ShtorkaMockSizeControls(shtorkaSize: $shtorkaSize)
        }
    }
}

private extension ShtorkaShowcaseSheet {
    enum Constants {
        static let searchRowHeightLimit: CGFloat = 250
    }
}

private struct ShtorkaMockSizeControls: View {
    @Binding var shtorkaSize: ShtorkaSize

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ShtorkaSize.allCases, id: \.self) { size in
                SwiftUI.Button {
                    shtorkaSize = size
                } label: {
                    Text(String(describing: size))
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(background(for: size), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private func background(for size: ShtorkaSize) -> Color {
        shtorkaSize == size ? DesignSystem.Color.bgTertiary : DesignSystem.Color.bgSecondary
    }
}

struct ShtorkaMockPresentationRow: View {
    let onAlertTap: () -> Void
    let onDialogTap: () -> Void
    let onSheetTap: () -> Void
    let onCoverTap: () -> Void
    let onSheetItemTap: () -> Void
    let onCoverItemTap: () -> Void
    let onAlertItemTap: () -> Void
    let onLegacySheetTap: () -> Void
    let onToastTap: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                button(title: "Alert", icon: "exclamationmark.bubble", action: onAlertTap)
                button(title: "Dialog", icon: "ellipsis.circle", action: onDialogTap)
                button(title: "Sheet", icon: "rectangle.bottomhalf.filled", action: onSheetTap)
                button(title: "Cover", icon: "rectangle.fill", action: onCoverTap)
                button(title: "Sheet by item", icon: "rectangle.bottomhalf.inset.filled", action: onSheetItemTap)
                button(title: "Cover by item", icon: "rectangle.inset.filled", action: onCoverItemTap)
                button(title: "Alert by item", icon: "exclamationmark.bubble.circle", action: onAlertItemTap)
                button(title: "Legacy", icon: "rectangle.bottomthird.inset.filled", action: onLegacySheetTap)
                button(title: "Toast", icon: "bell.badge", action: onToastTap)
            }
        }
    }

    private func button(title: String, icon: String, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DesignSystem.Color.iconPrimary)

                Text(title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(DesignSystem.Color.bgTertiary, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ShtorkaMockStateLine: View {
    let size: ShtorkaSize

    @State private var visited: Set<ShtorkaSize> = []

    var body: some View {
        Text("Shtorka: \(String(describing: size)) · seen \(visited.count)/\(ShtorkaSize.allCases.count)")
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .onAppear { visited.insert(size) }
            .onChange(of: size) { visited.insert($0) }
    }
}

struct ShtorkaMockBackdrop: View {
    let shtorkaSize: ShtorkaSize
    let onRowTap: (Int) -> Void
    let onAlertTap: () -> Void
    let onDialogTap: () -> Void
    let onSheetTap: () -> Void
    let onCoverTap: () -> Void
    let onSheetItemTap: () -> Void
    let onCoverItemTap: () -> Void
    let onAlertItemTap: () -> Void
    let onLegacySheetTap: () -> Void
    let onToastTap: () -> Void

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Backdrop — everything here is raised from the root view; a row tap hides the shtorka and opens a screen")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            ShtorkaMockStateLine(size: shtorkaSize)

            ShtorkaMockPresentationRow(
                onAlertTap: onAlertTap,
                onDialogTap: onDialogTap,
                onSheetTap: onSheetTap,
                onCoverTap: onCoverTap,
                onSheetItemTap: onSheetItemTap,
                onCoverItemTap: onCoverItemTap,
                onAlertItemTap: onAlertItemTap,
                onLegacySheetTap: onLegacySheetTap,
                onToastTap: onToastTap
            )

            input

            ForEach(0 ..< 5) { index in
                SwiftUI.Button {
                    onRowTap(index)
                } label: {
                    Text("Wallet row \(index)")
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
    }

    private var input: some View {
        TextField("Dummy input — raises the keyboard from the root view", text: $inputText)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .focused($isInputFocused)
            .submitLabel(.done)
            .onSubmit { isInputFocused = false }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
