//
//  KeychainManager.swift
//  IELTSPart2Coach
//
//  Created on 2025-11-10
//  Phase 5: Secure API key storage using iOS Keychain
//

import Foundation
import Security

@MainActor
class KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    // Keychain service identifier (unique to this app)
    private let service = "com.Charlie.IELTSPart2Coach"

    // MARK: - Public API

    /// Save API key to Keychain (encrypted at rest by iOS)
    func saveAPIKey(_ key: String) throws {
        guard !key.isEmpty else {
            throw KeychainError.emptyKey
        }

        let keyData = key.data(using: .utf8)!

        // Keychain query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "openrouter_api_key",
            kSecValueData as String: keyData
        ]

        // Delete existing key first (if any)
        SecItemDelete(query as CFDictionary)

        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            #if DEBUG
            print("❌ Failed to save API key to Keychain: \(status)")
            #endif
            throw KeychainError.saveFailed(status: status)
        }

        #if DEBUG
        print("✅ API key saved to Keychain successfully")
        #endif
    }

    /// Retrieve API key from Keychain
    func getAPIKey() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "openrouter_api_key",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.keyNotFound
            }
            throw KeychainError.retrievalFailed(status: status)
        }

        guard let keyData = result as? Data,
              let key = String(data: keyData, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return key
    }

    /// Delete API key from Keychain
    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "openrouter_api_key"
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }

        #if DEBUG
        print("🗑️ API key deleted from Keychain")
        #endif
    }

    /// Check if API key exists in Keychain
    func hasAPIKey() -> Bool {
        do {
            _ = try getAPIKey()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Device ID (Backend Migration)

    /// Save device ID to Keychain (for backend rate limiting)
    /// Backend migration (2025-11-22): Device ID replaces API key for backend proxy mode
    func saveDeviceID(_ id: String) throws {
        guard !id.isEmpty else {
            throw KeychainError.emptyKey
        }

        let keyData = id.data(using: .utf8)!

        // Keychain query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "device_id",
            kSecValueData as String: keyData
        ]

        // Delete existing ID first (if any)
        SecItemDelete(query as CFDictionary)

        // Add new ID
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            #if DEBUG
            print("❌ Failed to save device ID to Keychain: \(status)")
            #endif
            throw KeychainError.saveFailed(status: status)
        }

        #if DEBUG
        print("✅ Device ID saved to Keychain successfully")
        #endif
    }

    /// Retrieve device ID from Keychain
    func getDeviceID() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "device_id",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.keyNotFound
            }
            throw KeychainError.retrievalFailed(status: status)
        }

        guard let keyData = result as? Data,
              let deviceID = String(data: keyData, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return deviceID
    }
}

// MARK: - Error Types

enum KeychainError: LocalizedError {
    case emptyKey
    case saveFailed(status: OSStatus)
    case retrievalFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    case keyNotFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "Cannot save empty API key"
        case .saveFailed(let status):
            return "Failed to save API key (status: \(status))"
        case .retrievalFailed(let status):
            return "Failed to retrieve API key (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete API key (status: \(status))"
        case .keyNotFound:
            return "API key not found in Keychain"
        case .invalidData:
            return "Invalid API key data"
        }
    }
}
