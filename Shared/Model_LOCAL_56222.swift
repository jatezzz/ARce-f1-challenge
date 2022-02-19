// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
// https://app.quicktype.io
//
//   let welcome = try? newJSONDecoder().decode(Welcome.self, from: jsonData)

import Foundation

// MARK: - Welcome
struct LapData: Codable {
    let items: [Motion]
    let hasMore: Bool
    let limit, offset, count: Int
}

// MARK: - Motion new

// from here: "https://yj6gtaivgb4zvoj-fortatp.adb.ap-sydney-1.oraclecloudapps.com/ords/anziot/f1/motion/recent"
// or for an entire lap here: "https://yj6gtaivgb4zvoj-fortatp.adb.ap-sydney-1.oraclecloudapps.com/ords/anziot/f1/carData/lastlap"

// to be replaced by the most generic one: https://yj6gtaivgb4zvoj-fortatp.adb.ap-sydney-1.oraclecloudapps.com/ords/anziot/f1/carData/:sessionid/:lap
// list of tracks from here: https://yj6gtaivgb4zvoj-fortatp.adb.ap-sydney-1.oraclecloudapps.com/ords/anziot/f1/sessions

struct Motion: Codable {
    let id: String?
    let mTimestamp: String
    let mWorldposx, mWorldposy, mWorldposz: Float
    let mFrame, mSpeed, mEngineRPM, mGear: Int
    let mYaw, mPitch, mRoll: Double

    enum CodingKeys: String, CodingKey {
        case id
        case mWorldposx = "m_worldposx"
        case mWorldposy = "m_worldposy"
        case mWorldposz = "m_worldposz"
        case mTimestamp = "m_timestamp"
        case mFrame = "m_frame"
        case mSpeed = "m_speed"
        case mEngineRPM = "m_enginerpm"
        case mGear = "m_gear"
        case mYaw = "m_yaw"
        case mPitch = "m_pitch"
        case mRoll = "m_roll"
    }
}

// MARK: - Sessions

struct SessionsData: Codable {
    let items: [Session]
    let hasMore: Bool
    let limit, offset, count: Int
}

struct Session: Codable {
    let mSessionid, laps: Int
    let sessionTime: String

    enum CodingKeys: String, CodingKey {
        case mSessionid = "m_sessionid"
        case laps
        case sessionTime = "session_time"
    }
}

// MARK: - CarData

// from here: "https://yj6gtaivgb4zvoj-fortatp.adb.ap-sydney-1.oraclecloudapps.com/ords/anziot/f1/carData/recent"
struct CarData: Codable {
    let mFrame, mSpeed: Int
    let mBrake, mThrottle: Double
    let mGear, mEnginerpm: Int
    let mWorldposx, mWorldposy: Double

    enum CodingKeys: String, CodingKey {
        case mFrame = "m_frame"
        case mSpeed = "m_speed"
        case mBrake = "m_brake"
        case mThrottle = "m_throttle"
        case mGear = "m_gear"
        case mEnginerpm = "m_enginerpm"
        case mWorldposx = "m_worldposx"
        case mWorldposy = "m_worldposy"
    }
}



