//
//  ScreenshotPreventView.swift
//  SecureScreenShotChatGPT
//
//  Created by Apple on 24/03/26.
//

import SwiftUI
import UIKit

// MARK: - Screenshot Prevent View
public struct ScreenshotPreventView<Content: View>: UIViewRepresentable {

    let content: Content
    let isImageDisplay: Bool

    public init(isImageDisplay: Bool = false, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isImageDisplay = isImageDisplay
    }
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    public func makeUIView(context: Context) -> UIView {
            let container = UIView()
     
            if isImageDisplay {
                // Image Underlay - Visible in SS if isImageDisplay is true
                let imageView = UIImageView()
                imageView.image = UIImage(named: "screenshotPreventionImage")
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(imageView)
                
                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: container.topAnchor),
                    imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                    imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
                ])
            } else {
                // Warning Label (Underlay - Visible in SS)
                let label = UILabel()
                label.text = "Screenshot Prevention"
                label.textColor = .white
                label.backgroundColor = .black
                label.textAlignment = .center
                label.font = .boldSystemFont(ofSize: 22)
                label.numberOfLines = 0
                label.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(label)
                
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: container.topAnchor),
                    label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                    label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    label.trailingAnchor.constraint(equalTo: container.trailingAnchor)
                ])
            }
     
            //  Secure Layer Overlay - Hidden in SS
            let textField = UITextField()
            textField.isSecureTextEntry = true
            textField.isUserInteractionEnabled = false
            
            guard let secureView = textField.layer.sublayers?.first?.delegate as? UIView else {
                return container
            }
     
            secureView.subviews.forEach { $0.removeFromSuperview() }
            secureView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(secureView)
     
            // SwiftUI Content (Hosting inside secure layer)
            let hosting = UIHostingController(rootView: content)
            hosting.view.backgroundColor = .systemBackground
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            secureView.addSubview(hosting.view)
     
            NSLayoutConstraint.activate([
                // Secure view constraints
                secureView.topAnchor.constraint(equalTo: container.topAnchor),
                secureView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                secureView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                secureView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
     
                // Hosting view constraints
                hosting.view.topAnchor.constraint(equalTo: secureView.topAnchor),
                hosting.view.bottomAnchor.constraint(equalTo: secureView.bottomAnchor),
                hosting.view.leadingAnchor.constraint(equalTo: secureView.leadingAnchor),
                hosting.view.trailingAnchor.constraint(equalTo: secureView.trailingAnchor)
            ])
     
            context.coordinator.startListening()
            return container
        }

   public func updateUIView(_ uiView: UIView, context: Context) {
        print("updateView Call")
    }

    // MARK: - Coordinator
  public  class Coordinator {
        func startListening() {

            // Screenshot taken
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(screenshotTaken),
                name: UIApplication.userDidTakeScreenshotNotification,
                object: nil
            )

            // Screen recording detection
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(screenRecordingChanged),
                name: UIScreen.capturedDidChangeNotification,
                object: nil
            )
        }

        @objc func screenshotTaken() {
            print("📸 Screenshot detected 2")
        }

        @objc func screenRecordingChanged() {
            if UIScreen.main.isCaptured {
                print("🎥 Screen recording ON")
            } else {
                print("🎥 Screen recording OFF")
            }
        }
    }
}

extension View {
   public func preventScreenshot(isImageDisplay: Bool = false) -> some View {
        ScreenshotPreventView(isImageDisplay: isImageDisplay) {
            self
        }
    }

    // Compatibility overload to resolve Undefined Symbol errors
    public func preventScreenshot(
        onScreenshot: (() -> Void)? = nil,
        onRecordingChange: ((Bool) -> Void)? = nil
    ) -> some View {
        self.preventScreenshot(isImageDisplay: false)
    }
}
extension UIApplication {
    
    var currentWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}


