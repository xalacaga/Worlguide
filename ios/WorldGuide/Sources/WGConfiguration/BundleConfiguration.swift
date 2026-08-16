import Foundation

/// Reads configuration from the app bundle's Info.plist, itself populated
/// from `Secrets.xcconfig` at build time (never hardcoded). Wiring the real
/// Info.plist keys is the manual Xcode step described in the README, since
/// no App target exists yet in this scaffolding.
public struct BundleConfiguration: ConfigurationProviding {
    private let bundle: Bundle

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    public func string(forKey key: ConfigurationKey) -> String? {
        bundle.object(forInfoDictionaryKey: key.rawValue) as? String
    }
}
