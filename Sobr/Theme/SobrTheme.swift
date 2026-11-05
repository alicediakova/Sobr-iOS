import SwiftUI
import UIKit

extension Color {
    static let sobrBg = SobrColor.dynamic(light: 0xFBF5F4, dark: 0x0E0A0B)
    static let sobrCard = SobrColor.dynamic(light: 0xFFFFFF, dark: 0x1E1718)
    static let sobrLabel = SobrColor.dynamic(light: 0x1F1416, dark: 0xFFF7F7)
    static let sobrSecondary = SobrColor.dynamic(light: 0x6E6264, dark: 0xB8ADAF)
    static let sobrTertiary = SobrColor.dynamic(light: 0xD6CBCC, dark: 0x4A3F41)
    static let sobrAccent = SobrColor.dynamic(light: 0x7A1F3D, dark: 0xF28B9B)
    static let sobrOnAccent = SobrColor.dynamic(light: 0xFFFFFF, dark: 0x1A0B0E)
    static let sobrWarning = SobrColor.dynamic(light: 0xA16207, dark: 0xF5C26B)
    static let sobrDestructive = SobrColor.dynamic(light: 0xC4161C, dark: 0xFF6961)
    static let sobrTrack = SobrColor.dynamic(light: 0xF2E4E6, dark: 0x3A2E30)

    static let sobrAccentSoft = Color(uiColor: UIColor { trait in
        let accent = trait.userInterfaceStyle == .dark ? UIColor(sobrHex: 0xF28B9B) : UIColor(sobrHex: 0x7A1F3D)
        let alpha: CGFloat = trait.userInterfaceStyle == .dark ? 0.20 : 0.12
        return accent.withAlphaComponent(alpha)
    })
}

enum SobrColor {
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { trait in
            UIColor(sobrHex: trait.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(sobrHex hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}

struct SobrCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.sobrCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func sobrCard() -> some View {
        modifier(SobrCardModifier())
    }

    func sobrScreen() -> some View {
        background(Color.sobrBg.ignoresSafeArea())
    }
}

struct PrimaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.sobrOnAccent)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(Color.sobrAccent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
