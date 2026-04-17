// qMD - Shared welcome/branding image view
// Loads the bundled welcome.png and displays it with rounded corners.
// Used in both the welcome screen and the About panel.

import SwiftUI

struct WelcomeImageView: View {
    var maxWidth: CGFloat = 400
    var cornerRadius: CGFloat = 12

    var body: some View {
        if let url = Bundle.module.url(forResource: "qmd.welcome", withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: maxWidth)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}
