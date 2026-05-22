# SecureShieldKit

A comprehensive iOS security framework built with Swift Package Manager (SPM) that provides runtime protection, jailbreak detection, SSL pinning, encryption utilities, reverse engineering detection, secure networking, screenshot prevention, and device trust validation.

## Features

### Runtime Security
- Runtime integrity monitoring
- Runtime hook detection
- Anti-debugging protection
- App integrity validation
- Tamper detection

### Jailbreak Detection
- Detects common jailbreak artifacts
- Suspicious URL scheme validation
- Writable system path verification
- Jailbreak bypass detection

### Reverse Engineering Protection
- Dynamic library inspection
- Frida detection
- Cycript detection
- Objection detection
- Debug server detection
- Reverse engineering environment detection

### SSL Pinning
- Certificate pinning
- Public key pinning
- SHA256 hash validation
- Fail-open or fail-closed behavior

### Encryption Utilities
- AES-GCM (256-bit) encryption
- RSA encryption and decryption
- Digital signatures
- Signature verification
- Secure key generation

### Device Trust Validation
- DeviceCheck integration
- App Attest support
- Device trust verification

### Secure Networking
- Generic API client
- Request interceptors
- Multipart upload support
- Token management
- Response parsing
- Secure URLSession configuration

### Privacy Protection
- Screenshot prevention view
- Screen capture detection
- Runtime screen monitoring

### Threat Monitoring
- Threat classification
- Threat severity levels
- Security event tracking
- Runtime threat reporting

---

## Requirements

| Platform | Version |
|-----------|----------|
| iOS | 15.0+ |
| macOS | 12.0+ |
| Swift | 5.9+ |

---

## Installation

### Swift Package Manager

Add SecureShieldKit to your `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/your-org/SecureShieldKit.git",
        from: "1.0.0"
    )
]
```

Add the dependency to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        "SecureShieldKit"
    ]
)
```

Or add it directly from Xcode:

1. File → Add Package Dependencies
2. Enter repository URL
3. Select version
4. Add package

---

## Quick Start

### Configure SecureShield

```swift
import SecureShieldKit

let configuration = SecureShieldConfiguration(
    enableRuntimeMonitoring: true,
    monitoringInterval: 15,
    failClosedOnPinningError: true,
    checkNetworkSecurity: true,
    checkScreenCapture: true
)

SecureShield.configure(configuration)
SecureShield.start()
```

---

## Runtime Monitoring

Enable continuous security monitoring:

```swift
SecureShield.start()
```

Stop monitoring:

```swift
SecureShield.stop()
```

Track custom security events:

```swift
SecureShield.trackEvent(
    name: "SensitiveOperation",
    properties: [
        "module": "Payments"
    ]
)
```

---

## AES Encryption

### Generate Key

```swift
let key = AESEncryption.generateKey()
```

### Encrypt Data

```swift
let encrypted = try AESEncryption.encrypt(
    data,
    using: key
)
```

### Decrypt Data

```swift
let decrypted = try AESEncryption.decrypt(
    encrypted,
    using: key
)
```

---

## RSA Encryption

### Generate Key Pair

```swift
let keyPair = try RAS56Encryption.generateKeyPair()
```

### Encrypt

```swift
let encrypted = try RAS56Encryption.encrypt(
    messageData,
    publicKey: keyPair.publicKey
)
```

### Decrypt

```swift
let decrypted = try RAS56Encryption.decrypt(
    encryptedData,
    privateKey: keyPair.privateKey
)
```

### Sign Data

```swift
let signature = try RAS56Encryption.sign(
    data,
    privateKey: keyPair.privateKey
)
```

### Verify Signature

```swift
let isValid = try RAS56Encryption.verify(
    signature,
    for: data,
    publicKey: keyPair.publicKey
)
```

---

## SSL Pinning

Configure certificate pinning:

```swift
let certificateData: Data = ...

SSLPinning.shared.configure(
    certificates: [certificateData],
    publicKeys: [],
    failClosed: true
)
```

Use with URLSession:

```swift
let session = URLSession(
    configuration: .default,
    delegate: SSLPinning.shared,
    delegateQueue: nil
)
```

---

## Secure Networking

### Define Endpoint

```swift
struct UserEndpoint: Endpoint {

    let userId: Int

    var baseURL: String {
        "https://api.example.com"
    }

    var path: String {
        "/users/\(userId)"
    }

    var method: HTTPMethod {
        .get
    }

    var headers: [String : String]? {
        ["Authorization": "Bearer token"]
    }

    var queryParameters: [String : String]? {
        nil
    }

    var body: Data? {
        nil
    }
}
```

### Execute Request

```swift
let manager = NetworkManager.shared

let user: User = try await manager.request(
    UserEndpoint(userId: 1)
)
```

---

## Authentication Interceptor

Inject tokens automatically:

```swift
let interceptor = AuthInterceptor {
    await TokenManager.shared.fetchToken()
}

let manager = NetworkManager(
    interceptors: [interceptor]
)
```

---

## Screenshot Prevention

Protect sensitive content from screenshots:

```swift
ScreenshotPreventView {

    VStack {
        Text("Sensitive Information")
    }

}
```

Protect image content:

```swift
ScreenshotPreventView(
    isImageDisplay: true
) {
    Image("secret-image")
}
```

---

## Device Trust Validation

Check DeviceCheck support:

```swift
let trustService = DeviceTrustService()

if trustService.isDeviceCheckSupported() {
    print("DeviceCheck available")
}
```

Generate DeviceCheck token:

```swift
let token = try await trustService.deviceCheckToken()
```

Check App Attest availability:

```swift
if trustService.isAppAttestSupported() {
    print("App Attest supported")
}
```

---

## Runtime Protection

Register protected selectors:

```swift
RuntimeProtector.shared.protect(
    selector: #selector(MyClass.secureMethod),
    on: MyClass.self
)
```

Validate protections:

```swift
let valid = RuntimeProtector.shared
    .validateProtectedSelectors()
```

---

## Threat Types

The framework can detect:

- Jailbreak
- Jailbreak bypass
- Runtime hooks
- Frida
- Debugger attachment
- Integrity violations
- Reverse engineering tools
- Simulator execution
- SSL pinning failures
- App tampering
- Unsecured WiFi
- Unsecured hotspot
- Active VPN
- Screen capture events

Threat levels:

```swift
ThreatLevel.low
ThreatLevel.medium
ThreatLevel.high
ThreatLevel.critical
```

---

## Secure URLSession

Create a hardened networking session:

```swift
let session = URLSession.secureSession(
    timeout: 30
)
```

Features include:

- Secure caching policies
- Connectivity handling
- Hardened timeout settings
- Safer network defaults

---

## Testing

Run package tests:

```bash
swift test
```

Run from Xcode:

```bash
⌘ + U
```

---

## Project Structure

```text
SecureShieldKit
│
├── PublicAPI
│   ├── SecureShield
│   ├── SecureShieldConfiguration
│   ├── AESEncryption
│   ├── RAS56Encryption
│   └── Threat
│
├── RuntimeProtection
│   ├── RuntimeProtector
│   ├── DeviceTrustService
│   └── SimulatorDetector
│
├── SSLPinning
│   └── SSLPinning
│
├── ReverseEngineering
│   └── ReverseEngineeringDetector
│
├── Networking
│   ├── NetworkManager
│   ├── APIManager
│   ├── Endpoint
│   ├── RequestBuilder
│   └── ResponseParser
│
├── Utilities
│   ├── Crypto
│   ├── DyldImageScanner
│   └── EncryptedConfiguration
│
└── ScreenShotPrevention
    └── ScreenshotPreventView
```

---

## Security Notes

- No security framework can guarantee absolute protection.
- Combine multiple security controls for best results.
- Regularly update certificates and cryptographic keys.
- Monitor security events in production.
- Validate all server-side requests independently.

---
## Set up custom image for screenShot prevention
Set up image in asset name should be **"screenshotPreventionImage"**

----
## License

MIT License

Copyright (c) 2026 SecureShieldKit

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files to deal in the Software without restriction.
