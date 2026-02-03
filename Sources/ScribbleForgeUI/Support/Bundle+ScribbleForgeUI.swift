import Foundation
import UIKit

enum ScribbleForgeUIResources {
    static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let baseBundle = Bundle(for: BundleToken.self)
        if let resourceURL = baseBundle.url(forResource: "ScribbleForgeUI", withExtension: "bundle"),
           let resourceBundle = Bundle(url: resourceURL) {
            return resourceBundle
        }
        if let mainBundlePath = Bundle.main.path(forResource: "ScribbleForgeUI", ofType: "bundle"),
           let mainBundle = Bundle(path: mainBundlePath) {
            return mainBundle
        }
        return baseBundle
        #endif
    }

    static func image(named name: String) -> UIImage? {
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
}

private final class BundleToken {}
