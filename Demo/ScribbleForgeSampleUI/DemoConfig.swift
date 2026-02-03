import Foundation
import ScribbleForge

enum DemoConfig {
    static func buildJoinOptions() -> JoinRoomOptions? {
        let roomId = string(for: "ScribbleForgeRoomId")
        let roomToken = string(for: "ScribbleForgeRoomToken")
        let userId = string(for: "ScribbleForgeUserId")
        let regionEndpoint = string(for: "ScribbleForgeRegionEndpoint")
        let writable = bool(for: "ScribbleForgeWritable", defaultValue: true)

        guard !roomId.isEmpty, !roomToken.isEmpty, !userId.isEmpty else {
            return nil
        }

        let region: ScribbleForge.Region
        if regionEndpoint.isEmpty {
            region = .cn_hz
        } else {
            region = .custom(endPoint: regionEndpoint)
        }

        let options = JoinRoomOptions(
            writable: writable,
            authOption: .init(
                roomId: roomId,
                token: roomToken,
                userId: userId,
                nickName: userId,
                region: region
            ),
            logOption: .init(
                logDirPath: nil,
                allowRemoteLog: true,
                allowConsoleLog: true,
                allowConsoleVerboseLog: false,
                allowPerfLog: true
            ),
            useSnapshotFetch: true,
            mergeThrottleLevel: .high,
            joinRoomTimeout: nil
        )

        return options
    }

    static func rtmAppId() -> String {
        return string(for: "ScribbleForgeRtmAppId")
    }

    static func rtmToken() -> String {
        return string(for: "ScribbleForgeRtmToken")
    }

    private static let roomConfig: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "RoomConfig", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any] else {
            return [:]
        }
        return dict
    }()

    private static func string(for key: String) -> String {
        let value = roomConfig[key] as? String
        return value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func bool(for key: String, defaultValue: Bool) -> Bool {
        guard let value = roomConfig[key] else {
            return defaultValue
        }
        if let boolValue = value as? Bool {
            return boolValue
        }
        if let stringValue = value as? String {
            return (stringValue as NSString).boolValue
        }
        if let numberValue = value as? NSNumber {
            return numberValue.boolValue
        }
        return defaultValue
    }

}
