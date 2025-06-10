//
//  WalletConnectQRScanView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

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

    @ViewBuilder
    private var pasteFromClipboardButton: some View {
        if let pasteFromClipboardButton = viewModel.state.pasteFromClipboardButton {
            Button(action: { viewModel.handle(viewEvent: .pasteFromClipboardButtonTapped(pasteFromClipboardButton.clipboardURI)) }) {
                HStack(spacing: 10) {
                    Text(pasteFromClipboardButton.title)
                        .style(Fonts.Bold.callout, color: Colors.Text.constantWhite)

                    pasteFromClipboardButton.asset.image
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Colors.Text.constantWhite)
                }
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
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
        ForEach(buttons, id: \.self) { button in
            Button(button.title, role: button.role?.toSwiftUIButtonRole, action: button.action)
        }
    }
}

private extension WalletConnectQRScanViewState.DialogButtonRole {
    var toSwiftUIButtonRole: ButtonRole {
        switch self {
        case .cancel: .cancel
        }
    }
}
