//
//  WalletConnectQRScanView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct WalletConnectQRScanView: View {
    @ObservedObject var viewModel: WalletConnectQRScanViewModel

    var body: some View {
        ZStack {
            cameraView
                .ignoresSafeArea()
                .animation(.default, value: viewModel.state.hasCameraAccess)

            dimmingBackground
            navigationBar
            scannerOverlayElements
        }
        .confirmationDialog(for: viewModel.state.confirmationDialog, dismissAction: dismissDialogAction)
        .onAppear {
            viewModel.handle(viewEvent: .viewDidAppear)
        }
    }

    @ViewBuilder
    private var cameraView: some View {
        if viewModel.state.hasCameraAccess {
            QRScannerView(
                code: Binding(
                    get: { "" },
                    set: { qrCode in
                        viewModel.handle(viewEvent: .qrCodeParsed(qrCode))
                    }
                )
            )
            .transition(.opacity)
        } else {
            Color.black
                .transition(.opacity)
        }
    }

    private var dimmingBackground: some View {
        Colors.Overlays.overlaySecondary
            .ignoresSafeArea()
            .reverseMask(alignment: .center) {
                scannerRectangle(fillColor: .black)
            }
    }

    private var navigationBar: some View {
        VStack {
            ZStack {
                navigationCloseButton

                Text(viewModel.state.navigationBar.title)
                    .style(Fonts.Bold.body, color: Colors.Text.constantWhite)
            }
            .frame(height: 44)
            .padding(.horizontal, 16)

            Spacer()
        }
    }

    private var navigationCloseButton: some View {
        HStack {
            Button(action: { viewModel.handle(viewEvent: .navigationCloseButtonTapped) }) {
                Text(viewModel.state.navigationBar.closeButtonTitle)
                    .style(Fonts.Regular.body, color: Colors.Text.constantWhite)
                    .contentShape(.rect)
            }

            Spacer()
        }
    }

    private var scannerOverlayElements: some View {
        scannerRectangle()
            .overlay {
                CornerArcsBorder(cornerSize: CGSize(width: 30, height: 30), cornerRadius: 16, lineWidth: 4)
                    .stroke(Colors.Icon.constant, lineWidth: 4)
                    .padding(.horizontal, 38)
                    .padding(.vertical, -2)
            }
            .overlay(alignment: .top) {
                scannerHint
                    .padding(.bottom, 48)
                    .alignmentGuide(.top) {
                        $0[.bottom]
                    }
            }
            .overlay(alignment: .bottom) {
                pasteFromClipboardButton
                    .padding(.top, 32)
                    .alignmentGuide(.bottom) {
                        $0[.top]
                    }
            }
    }

    private var scannerHint: some View {
        Text(viewModel.state.hint)
            .style(Fonts.Regular.subheadline, color: Colors.Text.constantWhite)
            .frame(maxWidth: 200)
            .multilineTextAlignment(.center)
    }

    private var pasteFromClipboardButton: some View {
        PasteButton(payloadType: String.self) { clipboardStrings in
            // [REDACTED_USERNAME], this handler may be called from background thread...
            // Compiler @MainActor checks from both view and view model are simply ignored.
            Task { @MainActor in
                viewModel.handle(viewEvent: .pasteFromClipboardButtonTapped(clipboardStrings.first))
            }
        }
        .labelStyle(.titleAndIcon)
        .tint(.clear)
        .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.pasteButton)
    }

    private func scannerRectangle(fillColor: Color = .clear, strokeColor: Color = .clear) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(fillColor)
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 40)
    }

    private func dismissDialogAction() {
        viewModel.handle(viewEvent: .closeDialogButtonTapped)
    }
}

// MARK: - ModalDialogs wrappers

// [REDACTED_TODO_COMMENT]
private extension View {
    func confirmationDialog(
        for dialog: WalletConnectQRScanViewState.ConfirmationDialog?,
        dismissAction: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            dialog?.title ?? "",
            isPresented: Binding(
                get: { dialog != nil },
                set: { isPresented in
                    if !isPresented {
                        dismissAction()
                    }
                }
            ),
            titleVisibility: .visible,
            presenting: dialog,
            actions: { _ in
                dialog?.actions
            },
            message: { _ in
                Text(dialog?.subtitle ?? "")
            }
        )
    }
}

private extension WalletConnectQRScanViewState.ConfirmationDialog {
    var actions: some View {
        Button(button.title, action: button.action)
    }
}
