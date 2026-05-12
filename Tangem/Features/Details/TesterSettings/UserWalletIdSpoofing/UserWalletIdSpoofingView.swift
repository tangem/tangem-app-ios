//
//  UserWalletIdSpoofingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct UserWalletIdSpoofingView: View {
    @ObservedObject var viewModel: UserWalletIdSpoofingViewModel

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 16)) {
                warningBanner

                walletsSection

                mappingsSection
            }
            .interContentPadding(8)
        }
        .navigationBarTitle(Text("User Wallet ID Spoofing"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.presentAddMapping(currentWalletId: nil)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .sheet(isPresented: $viewModel.isAddSheetPresented) { addMappingSheet }
    }

    // MARK: - Sections

    private var warningBanner: some View {
        Text(
            """
            Spoofing breaks local data access for the spoofed wallet (encrypted private data, biometric encryption key, NFT cache, access code keychain) until the entry is removed and the app is restarted.

            New entries take effect after the next app restart.
            """
        )
        .font(.footnote)
        .foregroundColor(Color.red)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var walletsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Existing wallets")

            if viewModel.walletRows.isEmpty {
                Text("No wallets onboarded yet")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.walletRows) { row in
                        walletRowView(row)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Colors.Background.action)

                        if row.id != viewModel.walletRows.last?.id {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var mappingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionHeader(title: "Spoof mappings")

                Spacer()

                if !viewModel.spoofMappingRows.isEmpty {
                    Button("Clear all", action: viewModel.clearAllMappings)
                        .font(.footnote)
                        .foregroundColor(Color.red)
                        .padding(.trailing)
                }
            }

            if viewModel.spoofMappingRows.isEmpty {
                Text("No mappings configured")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.spoofMappingRows) { row in
                        mappingRowView(row)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Colors.Background.action)

                        if row.id != viewModel.spoofMappingRows.last?.id {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Rows

    private func walletRowView(_ row: UserWalletIdSpoofingViewModel.WalletRow) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.subheadline)
                    .foregroundColor(Colors.Text.primary1)

                Text(row.currentId)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Colors.Text.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let originalId = row.originalId {
                    Text("Spoofed from \(originalId)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(Color.orange)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            Button {
                viewModel.copyToClipboard(row.currentId)
            } label: {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(Color.blue)
            }

            Button {
                viewModel.presentAddMapping(currentWalletId: row.currentId)
            } label: {
                Image(systemName: "pencil.circle")
                    .foregroundColor(Color.blue)
            }
        }
    }

    private func mappingRowView(_ row: UserWalletIdSpoofingViewModel.SpoofMappingRow) -> some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.originalHex)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Colors.Text.primary1)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(.caption2))
                        .foregroundColor(Colors.Text.tertiary)

                    Text(row.spoofedHex)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color.orange)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            Button {
                viewModel.deleteMapping(originalHex: row.originalHex)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(Color.red)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
            .padding(.horizontal)
    }

    // MARK: - Add-mapping sheet

    private var addMappingSheet: some View {
        NavigationStack {
            ZStack {
                Colors.Background.secondary.edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Original hex")
                            .font(.footnote)
                            .foregroundColor(Colors.Text.secondary)

                        TextField("e.g., AABBCC…", text: $viewModel.draftOriginalHex)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding()
                            .border(Color.gray, width: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spoofed hex")
                            .font(.footnote)
                            .foregroundColor(Colors.Text.secondary)

                        TextField("e.g., 112233…", text: $viewModel.draftSpoofedHex)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding()
                            .border(Color.gray, width: 1)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle(Text("Add mapping"), displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel", action: viewModel.cancelDraftMapping),
                trailing: Button("Save", action: viewModel.saveDraftMapping)
            )
        }
    }
}
