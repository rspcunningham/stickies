import Foundation
import Security

enum CloudKitEntitlementStatus {
    static var canUseCloudKit: Bool {
        guard let task = SecTaskCreateFromSelf(nil),
              let services = SecTaskCopyValueForEntitlement(
                task,
                "com.apple.developer.icloud-services" as CFString,
                nil
              ) as? [String] else {
            return false
        }

        return services.contains("CloudKit")
    }
}
