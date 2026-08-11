import SwiftUI

/// Lightweight drawn keyboard — no external image asset required.
struct KeyboardArt: View {
    let isLocked: Bool

    private let keyRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.20, green: 0.23, blue: 0.28).opacity(isLocked ? 0.92 : 1))
                .shadow(color: .black.opacity(0.12), radius: 18, y: 10)

            VStack(spacing: 8) {
                ForEach(Array(keyRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 6) {
                        ForEach(row, id: \.self) { key in
                            keyCap(key)
                        }
                    }
                }

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(keyFill)
                    .frame(width: 160, height: 22)
                    .overlay {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(red: 0.75, green: 0.82, blue: 0.78))
                        }
                    }
            }
            .padding(18)
            .opacity(isLocked ? 0.55 : 1)

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(16)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isLocked)
        .accessibilityLabel(isLocked ? "Keyboard locked" : "Keyboard unlocked")
    }

    private var keyFill: Color {
        Color(red: 0.32, green: 0.36, blue: 0.42)
    }

    private func keyCap(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(Color(red: 0.88, green: 0.90, blue: 0.93))
            .frame(width: 26, height: 26)
            .background(keyFill, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}
