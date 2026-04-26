import AppKit
import SwiftUI

struct AppBundleIcon: View {
    let name: String
    var size: CGFloat
    var color: Color
    var rendersAsTemplate: Bool

    init(
        name: String,
        size: CGFloat = 18,
        color: Color,
        rendersAsTemplate: Bool = true
    ) {
        self.name = name
        self.size = size
        self.color = color
        self.rendersAsTemplate = rendersAsTemplate
    }

    var body: some View {
        Group {
            if let image = resolvedImage {
                Image(nsImage: image)
                    .renderingMode(rendersAsTemplate ? .template : .original)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(rendersAsTemplate ? color : .primary)
            } else {
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(color.opacity(0.8))
            }
        }
        .accessibilityHidden(true)
        .frame(width: size, height: size)
    }

    private var resolvedImage: NSImage? {
        AppBundleIconLoader.image(named: name)
    }
}

private enum AppBundleIconLoader {
    static func image(named name: String) -> NSImage? {
        if let image = Bundle.main.image(forResource: NSImage.Name(name)) {
            return image
        }

        if let image = Bundle.module.image(forResource: NSImage.Name(name)) {
            return image
        }

        return imageFromRawImageSet(named: name)
    }

    private static func imageFromRawImageSet(named name: String) -> NSImage? {
        let extensions = ["pdf", "png"]

        for fileExtension in extensions {
            if let resourceURL = Bundle.module.url(
                forResource: name,
                withExtension: fileExtension,
                subdirectory: "Assets.xcassets/\(name).imageset"
            ), let image = NSImage(contentsOf: resourceURL) {
                return image
            }
        }

        return nil
    }
}
