import SwiftUI
import ThinkingOrbs

@main
struct ThinkingOrbsDemoApp: App {
    var body: some Scene {
        WindowGroup {
            if let screen = UserDefaults.standard.string(forKey: "screen").flatMap(ShowcaseScreen.init) {
                ShowcaseRouter(screen: screen)
                    .preferredColorScheme(launchScheme)
            } else {
                DemoPage()
            }
        }
    }
}

/// The web demo (orbs.jakubantalik.com), natively: hero pills, the full
/// state gallery at both sizes, and a playground.
struct DemoPage: View {
    @State private var forcedScheme: ColorScheme? = launchScheme
    @State private var speed = 1.0
    @Environment(\.colorScheme) private var systemScheme

    private var scheme: ColorScheme { forcedScheme ?? systemScheme }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                HeroExamples(speed: speed)
                Gallery(speed: speed)
                Playground(speed: $speed)
                CodeBlock(title: "Install", code: ".package(url: \"https://github.com/hemal08ce094/ThinkingOrbsSwiftUI\", branch: \"main\")")
                CodeBlock(title: "Usage", code: "import ThinkingOrbs\n\nThinkingOrb(.listening, size: .large)")
                Text("Port of thinking-orbs by Jakub Antalik · MIT")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .frame(maxWidth: 883)
            .frame(maxWidth: .infinity)
        }
        .background(Surface.page.ignoresSafeArea())
        .preferredColorScheme(forcedScheme)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Thinking Orbs")
                    .font(.title2.weight(.semibold))
                Text("Dotted thought-orb loading indicators for AI & agent UIs")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                forcedScheme = scheme == .dark ? .light : .dark
            } label: {
                Image(systemName: scheme == .dark ? "sun.max" : "moon")
                    .frame(width: 36, height: 36)
                    .background(Surface.panel, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(scheme == .dark ? "Light mode" : "Dark mode")
        }
    }
}

/// `-scheme dark|light` launch argument, for screenshots.
let launchScheme: ColorScheme? = {
    switch UserDefaults.standard.string(forKey: "scheme") {
    case "dark": .dark
    case "light": .light
    default: nil
    }
}()

enum Surface {
    static let page = Color(dynamicLight: 0xfafafa, dark: 0x0a0a0a)
    static let panel = Color(dynamicLight: 0xf0f0f0, dark: 0x161616)
    static let pill = Color(dynamicLight: 0xffffff, dark: 0x1a1a1a)
    static let stroke = Color(dynamicLight: 0x000000, dark: 0xffffff).opacity(0.06)
}

extension Color {
    init(dynamicLight light: UInt32, dark: UInt32) {
        #if os(macOS)
        self.init(nsColor: NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .hex(dark) : .hex(light) })
        #else
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .hex(dark) : .hex(light) })
        #endif
    }
}

#if os(macOS)
extension NSColor {
    static func hex(_ v: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat(v >> 16 & 0xff) / 255, green: CGFloat(v >> 8 & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: 1)
    }
}
#else
extension UIColor {
    static func hex(_ v: UInt32) -> UIColor {
        UIColor(red: CGFloat(v >> 16 & 0xff) / 255, green: CGFloat(v >> 8 & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: 1)
    }
}
#endif
