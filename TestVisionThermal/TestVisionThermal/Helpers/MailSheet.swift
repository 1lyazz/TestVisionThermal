import MessageUI
import SwiftUI

final class MailSheet: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = MailSheet()

    var closeAction: (() -> Void)?
    private var isContactsShown = false
    private let application: UIApplication = .shared

    override private init() {}

    func presentMailSheet() {
        guard !isContactsShown else { return }

        if !MFMailComposeViewController.canSendMail() {
            presentAlert(
                title: Strings.mailUnavailableTitle,
                message: Strings.mailUnavailableMessage(AppConstants.getValue().appMail),
                primaryAction: .CinfigureMail,
                secondaryAction: .Cancel
            )
            return
        }
        isContactsShown = true

        let picker = MFMailComposeViewController()
        picker.setToRecipients([AppConstants.getValue().appMail])
        picker.setSubject(application.appName)
        picker.mailComposeDelegate = self
        UIApplication.shared.topViewController?.present(picker, animated: true)
    }

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
        isContactsShown = false
        closeAction?()
    }
}

func presentAlert(
    title: String,
    message: String,
    primaryAction: UIAlertAction,
    secondaryAction: UIAlertAction? = nil,
    tertiaryAction: UIAlertAction? = nil
) {
    DispatchQueue.main.async {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(primaryAction)
        if let secondary = secondaryAction { alert.addAction(secondary) }
        if let tertiary = tertiaryAction { alert.addAction(tertiary) }
        UIApplication.shared.topViewController?.present(alert, animated: true)
    }
}

extension UIAlertAction {
    static var CinfigureMail: UIAlertAction {
        UIAlertAction(title: Strings.setupButtonTitle, style: .default, handler: { _ in
            let messageURLString = "message://"
            guard let mailURL = URL(string: messageURLString) else { return }

            if UIApplication.shared.canOpenURL(mailURL) {
                UIApplication.shared.open(mailURL, options: [:], completionHandler: nil)
            } else if let mailAppStoreURL = URL(string: AppConstants.getValue().mailAppURL) {
                UIApplication.shared.open(mailAppStoreURL, options: [:], completionHandler: nil)
            }
        })
    }

    static var Cancel: UIAlertAction {
        UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel)
    }
}
