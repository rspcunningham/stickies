import Foundation
#if os(macOS)
import Security
#endif

public enum CloudKitEntitlementStatus {
    public static var canUseCloudKit: Bool {
        #if os(macOS)
        guard let task = SecTaskCreateFromSelf(nil),
              let services = SecTaskCopyValueForEntitlement(
                task,
                "com.apple.developer.icloud-services" as CFString,
                nil
              ) as? [String] else {
            return false
        }

        return services.contains("CloudKit")
        #else
        true
        #endif
    }
}
