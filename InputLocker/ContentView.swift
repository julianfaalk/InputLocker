//
//  ContentView.swift
//  InputLocker
//
//  Created by Julian Falk on 03.11.25.
//
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: LockViewModel

    var body: some View {
        ZStack {
            AngularGradient(
                gradient: Gradient(colors: [
                    Color(nsColor: .systemIndigo).opacity(0.4),
                    Color(nsColor: .systemBlue).opacity(0.3),
                    Color(nsColor: .systemPurple).opacity(0.35),
                    Color(nsColor: .systemTeal).opacity(0.25)
                ]),
                center: .center
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 32) {
                header
                statusCard
                instructions
            }
            .frame(maxWidth: 440, alignment: .leading)
            .padding(.horizontal, 40)
            .padding(.vertical, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 520, minHeight: 620)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            brandedIcon(size: 64, badgeSize: 16)
            VStack(alignment: .leading, spacing: 6) {
                Text("InputLocker")
                    .font(.system(size: 26, weight: .semibold))
                Text("Freeze keyboard, trackpad, and special keys while you clean up.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.thinMaterial.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.isLocked ? "Input Locked" : "Input Unlocked")
                    .font(.system(size: 22, weight: .medium))
                Text(viewModel.safetyTimeoutDescription)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Button(action: viewModel.toggleLock) {
                HStack(spacing: 8) {
                    brandedIcon(size: 28, badgeSize: 10)
                    Text(viewModel.toggleButtonTitle)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(viewModel.toggleShortcut)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(PrimaryButtonStyle(accent: viewModel.isLocked ? .orange : .blue))

            if !viewModel.hasAccessibilityPermission {
                VStack(spacing: 6) {
                    Label("Accessibility access required.", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.yellow)
                    Button("Open System Settings") {
                        viewModel.requestPermission()
                    }
                    .buttonStyle(LinkButtonStyle())
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .systemYellow).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Quick tips")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            instructionItem(
                icon: "command.circle.fill",
                title: "Unlock shortcut",
                detail: "Press ⌘U to unlock instantly — even when everything else is frozen."
            )
            instructionItem(
                icon: "timer",
                title: "Safety timer",
                detail: "We automatically unlock after the timeout in case you forget."
            )
            instructionItem(
                icon: "sparkles",
                title: "Ideal for cleaning",
                detail: "Trackpad, brightness, volume, and media keys stay silent while locked."
            )
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func instructionItem(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.system(size: 17, weight: .medium))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func brandedIcon(size: CGFloat, badgeSize: CGFloat) -> some View {
        let assetName = viewModel.isLocked ? "LockedIcon" : "UnlockedIcon"
        return Image(assetName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: size * 0.15, x: 0, y: size * 0.08)
            .overlay(alignment: .bottomTrailing) {
                lockStateBadge(size: badgeSize)
            }
    }

    private func lockStateBadge(size: CGFloat) -> some View {
        Circle()
            .fill(viewModel.isLocked ? Color.green : Color.orange)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: viewModel.isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: size * 0.6, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: Color.black.opacity(0.25), radius: size * 0.35, x: 0, y: size * 0.15)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accent,
                                accent.opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
