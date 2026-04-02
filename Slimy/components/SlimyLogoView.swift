import SwiftUI

struct SlimyLogoView: View {
    var size: CGFloat = 24

    private let slimyRed = Color(red: 0.94, green: 0.22, blue: 0.27)
    private let slimyDarkRed = Color(red: 0.78, green: 0.14, blue: 0.18)

    var body: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [slimyRed, slimyDarkRed, slimyRed.opacity(0.8), slimyRed],
                    center: .center
                ),
                lineWidth: size * 0.22
            )
            .frame(width: size * 0.7, height: size * 0.7)
            .shadow(color: slimyRed.opacity(0.4), radius: 2)
            .frame(width: size, height: size)
    }
}
