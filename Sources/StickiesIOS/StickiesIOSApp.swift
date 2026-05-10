import StickiesCore
import SwiftUI
import UIKit

@main
struct StickiesIOSApp: App {
    @UIApplicationDelegateAdaptor(StickiesIOSAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = StickiesIOSAppModel()

    var body: some Scene {
        WindowGroup {
            NotesListView(
                store: model.store,
                syncNow: { model.syncNow(reason: "manual") }
            )
            .onAppear {
                model.start()
                appDelegate.remoteNotificationHandler = {
                    model.syncNow(reason: "cloudkit-push")
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else {
                    return
                }

                model.syncNow(reason: "app-active")
            }
        }
    }
}

@MainActor
final class StickiesIOSAppModel: ObservableObject {
    let store = NoteStore()

    private var syncController: CloudNoteSyncController?
    private var hasStarted = false

    func start() {
        guard !hasStarted else {
            return
        }

        hasStarted = true
        store.start(createNoteIfEmpty: false)

        guard CloudKitEntitlementStatus.canUseCloudKit else {
            store.setLastError("CloudKit is not enabled for this build.")
            return
        }

        let syncController = CloudNoteSyncController(store: store)
        self.syncController = syncController
        syncController.start()
        UIApplication.shared.registerForRemoteNotifications()
    }

    func syncNow(reason: String) {
        syncController?.syncNow(reason: reason)
    }
}

final class StickiesIOSAppDelegate: NSObject, UIApplicationDelegate {
    var remoteNotificationHandler: (() -> Void)?

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task { @MainActor in
            remoteNotificationHandler?()
            completionHandler(.newData)
        }
    }
}
