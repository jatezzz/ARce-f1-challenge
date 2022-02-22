// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
// https://app.quicktype.io
//
//   let welcome = try? newJSONDecoder().decode(Welcome.self, from: jsonData)

import Foundation

// MARK: - LapData

typealias LapData = [Motion]

struct Motion: Codable {
    let mFrame: Int
    let mTimestamp: String
    let mCurrentLap, mSector, mLastLapTimeInMS, mSpeed: Int
    let mGear: Int
    let mEngineRPM: Int
    let mWorldposx, mWorldposy, mWorldposz: Double
    let mWorldforwarddirx, mWorldforwarddiry, mWorldforwarddirz, mWorldrightdirx: Int
    let mWorldrightdiry, mWorldrightdirz: Int
    let mYaw, mPitch, mRoll: Float
    let driver: String

    let throttle, steer, brake: Float

    enum CodingKeys: String, CodingKey {
        case mFrame = "M_FRAME"
        case mTimestamp = "M_TIMESTAMP"
        case mCurrentLap = "M_CURRENT_LAP"
        case mSector = "M_SECTOR"
        case mLastLapTimeInMS = "M_LAST_LAP_TIME_IN_MS"
        case mSpeed = "M_SPEED"
        case mGear = "M_GEAR"
        case throttle = "M_THROTTLE"
        case steer = "M_STEER"
        case brake = "M_BRAKE"
        case mEngineRPM = "M_ENGINERPM"
        case mWorldposx = "M_WORLDPOSX"
        case mWorldposy = "M_WORLDPOSY"
        case mWorldposz = "M_WORLDPOSZ"
        case mWorldforwarddirx = "M_WORLDFORWARDDIRX"
        case mWorldforwarddiry = "M_WORLDFORWARDDIRY"
        case mWorldforwarddirz = "M_WORLDFORWARDDIRZ"
        case mWorldrightdirx = "M_WORLDRIGHTDIRX"
        case mWorldrightdiry = "M_WORLDRIGHTDIRY"
        case mWorldrightdirz = "M_WORLDRIGHTDIRZ"
        case mYaw = "M_YAW"
        case mPitch = "M_PITCH"
        case mRoll = "M_ROLL"
        case driver = "DRIVER"
    }
}

// MARK: - Sessions

typealias SessionsData = [Session]

struct Session: Codable, Identifiable, Hashable {

    let id = UUID()

    let mSessionid: String
    let mGamehost: String
    let trackId: String
    let driver: String
    let sessionTime: String
    let laps: Int

    enum CodingKeys: String, CodingKey {
        case mSessionid = "M_SESSIONID"
        case mGamehost = "M_GAMEHOST"
        case trackId = "TRACKID"
        case driver = "DRIVER"
        case sessionTime = "SESSION_TIME"
        case laps = "LAPS"
    }
}



