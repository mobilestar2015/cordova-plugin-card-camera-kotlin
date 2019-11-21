/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller for this sample app.
*/

import UIKit
import AVFoundation
import MaterialComponents.MaterialButtons

class APLViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

	@IBOutlet var imageView: UIImageView?
	@IBOutlet var overlayView: UIView?
    @IBOutlet var overlayFrame1: UIView?
    @IBOutlet var overlayFrame2: UIView?
    
    @IBOutlet var overlayFrameView: UIView!
    /// The camera controls in the overlay view.
	@IBOutlet var takePictureButton: MDCFloatingButton?
    @IBOutlet var confirmPictureButton: MDCFloatingButton?
    @IBOutlet var confirmTextLabel: UILabel!
    @IBOutlet var takePictureTextLabel: UILabel!
    
    /// An image picker controller instance.
	var imagePickerController = UIImagePickerController()
	
    /// An array for storing captured images to display.
	var capturedImages = [UIImage]()
    
    var isTakingFrontPicture = true
    var circlePath = UIBezierPath()
    var frontPicFileURL: URL?
    var backPicFileURL: URL?
	
	// MARK: - View Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()

        imagePickerController.modalPresentationStyle = .currentContext
		imagePickerController.delegate = self
        
        confirmPictureButton?.setBackgroundColor(UIColor.blue)
        let checkMark = UIImage(named: "ic_checkmark")?.withRenderingMode(.alwaysTemplate)
        confirmPictureButton?.setImage(checkMark, for: .normal)
        
        takePictureButton?.setBackgroundColor(UIColor.red)
        
        overlayFrame1?.layer.cornerRadius = 8
        overlayFrame1?.layer.masksToBounds = true
        overlayFrame1?.layer.borderColor = UIColor.white.cgColor
        overlayFrame1?.layer.borderWidth = 2
        
        overlayFrame2?.layer.cornerRadius = 8
        overlayFrame2?.layer.masksToBounds = true
        overlayFrame2?.layer.borderColor = UIColor.white.cgColor
        overlayFrame2?.layer.borderWidth = 2
        
        showImagePickerForCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.imageView!.bounds.size.width, height: self.imageView!.bounds.size.height), cornerRadius: 0)
        let x: CGFloat = 16
        let width = self.imageView!.bounds.size.width - x * 2
        let height = width * 100 / 156
        let y = (self.imageView!.bounds.size.height - height) / 2
        circlePath = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: width, height: height), cornerRadius: 8)
        path.append(circlePath)
        path.usesEvenOddFillRule = true
        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fillLayer.opacity = 0.4
        fillLayer.fillColor = UIColor.lightGray.cgColor
    }

	func finishAndUpdate() {
		dismiss(animated: true, completion: { [weak self] in
			guard let self = self else {
				return
			}
			
			if !self.capturedImages.isEmpty {
				if self.capturedImages.count == 1 {
					// The camera took a single picture.
					self.imageView?.image = self.capturedImages[0]
				} else {
                    /*
                     The camera captured multiple pictures. Cycle through the
                     captured frames in the view, showing each one for 5 seconds
                     in an animation.
                    */
					self.imageView?.animationImages = self.capturedImages
                    // Show each captured photo for 5 seconds.
					self.imageView?.animationDuration = 5
                    // Animate the images indefinitely (show all photos).
					self.imageView?.animationRepeatCount = 0
					self.imageView?.startAnimating()
				}
				
				/*
                 Clear the array of captured images to start taking pictures
                 again.
                */
				self.capturedImages.removeAll()
			}
		})
	}
    
    func performCropAndSave() {
        UIGraphicsBeginImageContextWithOptions(cropArea.size, false, 0)
        imageView?.image?.draw(at:CGPoint(x:-cropArea.origin.x, y:-cropArea.origin.y))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let targetSize = CGSize(width: 800, height: 512)
        let resultImage = croppedImage?.resizeImage(image: croppedImage!, targetSize: targetSize)
        
        var filename: String;
        if (isTakingFrontPicture) {
            filename = "front_pic.jpg"
        } else {
            filename = "back_pic.jpg"
        }
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent(filename)
            if let imageData = resultImage!.jpegData(compressionQuality: 0.8) {
                try imageData.write(to: fileURL)
                if (isTakingFrontPicture) {
                    frontPicFileURL = fileURL
                } else {
                    backPicFileURL = fileURL
                }
            }
        } catch {
            print(error)
        }
    }
    
    var cropArea:CGRect
        {
        get{
            let factor = imageView!.image!.size.width/imageView!.frame.width
            let imageFrame = imageView!.imageFrame()
            let x = (circlePath.bounds.origin.x - imageFrame.origin.x) * factor
            let y = (circlePath.bounds.origin.y - imageFrame.origin.y) * factor
            let width =  circlePath.bounds.width * factor
            let height = circlePath.bounds.height * factor
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
	
	// MARK: - Toolbar Actions
	@IBAction func retakePhoto(_ sender: Any) {
        self.showImagePickerForCamera()
    }
    
    @IBAction func confirmPhoto(_ sender: Any) {
        // TODO: crop image & save
        self.performCropAndSave()
        if (isTakingFrontPicture) {
            isTakingFrontPicture = false
            confirmTextLabel.text = "Confirm picture of the back of the card"
            takePictureTextLabel.text = "Take a picture of the back of the card"
            self.showImagePickerForCamera()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    /// - Tag: TakePicture
    @IBAction func takePhoto(_ sender: UIButton) {
        imagePickerController.takePicture()
    }
    
    /// - Tag: CameraSourceType
	func showImagePickerForCamera() {
        
		let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		
		if authStatus == AVAuthorizationStatus.denied {
			// The system denied access to the camera. Alert the user.

			/*
             The user previously denied access to the camera. Tell the user this
             app requires camera access.
            */
			let alert = UIAlertController(title: "Unable to access the Camera",
										  message: "To turn on camera access, choose Settings > Privacy > Camera and turn on Camera access for this app.",
										  preferredStyle: UIAlertController.Style.alert)
			
			let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
			alert.addAction(okAction)
			
			let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
				// Take the user to the Settings app to change permissions.
				guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
				if UIApplication.shared.canOpenURL(settingsUrl) {
					UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
						// The resource finished opening.
					})
				}
			})
			alert.addAction(settingsAction)
			
			present(alert, animated: true, completion: nil)
		} else if authStatus == AVAuthorizationStatus.notDetermined {
            /*
             The user never granted or denied permission for media capture with
             the camera. Ask for permission.

             Note: The app must provide a `Privacy - Camera Usage Description`
             key in the Info.plist with a message telling the user why the app
             is requesting access to the device’s camera. See this app's
             Info.plist for such an example usage description.
            */
			AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
				if granted {
					DispatchQueue.main.async {
						self.showImagePicker(sourceType: UIImagePickerController.SourceType.camera)
					}
				}
			})
		} else {
            /*
             The user granted permission to access the camera. Present the
             picker for capture.

             Set the image picker `sourceType` property to
             `UIImagePickerController.SourceType.camera` to configure the picker
             for media capture instead of browsing saved media.
            */
			showImagePicker(sourceType: UIImagePickerController.SourceType.camera)
		}
	}

	func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        // Stop animating the images in the view.
		if (imageView?.isAnimating)! {
			imageView?.stopAnimating()
		}
		if !capturedImages.isEmpty {
			capturedImages.removeAll()
		}

		imagePickerController.sourceType = sourceType
		imagePickerController.modalPresentationStyle =
			(sourceType == UIImagePickerController.SourceType.camera) ?
				UIModalPresentationStyle.fullScreen : UIModalPresentationStyle.popover
		if sourceType == UIImagePickerController.SourceType.camera {
			/*
             The user tapped the camera button in the app's interface which
             specifies the device’s built-in camera as the source for the image
             picker controller.
            */

            /*
             Hide the default controls.
             This sample provides its own custom controls for still image
             capture in an overlay view.
            */
			imagePickerController.showsCameraControls = false
            imagePickerController.cameraCaptureMode = .photo
            
            let screenSize = imageView?.bounds.size
            let cameraHeight = screenSize!.width * 4 / 3
            let offsetY = (screenSize!.height + UIApplication.shared.statusBarFrame.height - cameraHeight) / 2
            
            let translate = CGAffineTransform(translationX: 0.0, y: offsetY); //This slots the preview exactly in the middle of the screen by moving it down 71 points
            imagePickerController.cameraViewTransform = translate;

			overlayView?.frame = (imagePickerController.cameraOverlayView?.frame)!
			imagePickerController.cameraOverlayView = overlayView
		}
		
        /*
         The creation and configuration of the camera or media browser
         interface is now complete.

         Asynchronously present the picker interface using the
         `present(_:animated:completion:)` method.
        */
		present(imagePickerController, animated: true, completion: {
			// The block to execute after the presentation finishes.
		})
	}
	
	// MARK: - UIImagePickerControllerDelegate
    /**
    You must implement the following methods that conform to the
    `UIImagePickerControllerDelegate` protocol to respond to user interactions
    with the image picker.

    When the user taps a button in the camera interface to accept a newly
    captured picture, the system notifies the delegate of the user’s choice by
    invoking the `imagePickerController(_:didFinishPickingMediaWithInfo:)`
    method. Your delegate object’s implementation of this method can perform
    any custom processing on the passed media, and should dismiss the picker.
    The delegate methods are always responsible for dismissing the picker when
    the operation completes.
    */
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            return
        }
        capturedImages.append(image)

        finishAndUpdate()
	}

    /**
    If the user cancels the operation, the system invokes the delegate's
    `imagePickerControllerDidCancel(_:)` method, and you should dismiss the
    picker.
    */
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: {
        /*
         The dismiss method calls this block after dismissing the image picker
         from the view controller stack. Perform any additional cleanup here.
        */
		})
	}
}

// MARK: - Utilities
private func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (key.rawValue, value) })
}

private func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

extension UIImageView
{
    func imageFrame()->CGRect
    {
        let imageViewSize = self.frame.size
        guard let imageSize = self.image?.size else
        {
            return CGRect.zero
        }
        let imageRatio = imageSize.width / imageSize.height
        let imageViewRatio = imageViewSize.width / imageViewSize.height
        if imageRatio < imageViewRatio
        {
            let scaleFactor = imageViewSize.height / imageSize.height
            let width = imageSize.width * scaleFactor
            let topLeftX = (imageViewSize.width - width) * 0.5
            return CGRect(x: topLeftX, y: 0, width: width, height: imageViewSize.height)
        }
        else
        {
            let scalFactor = imageViewSize.width / imageSize.width
            let height = imageSize.height * scalFactor
            let topLeftY = (imageViewSize.height - height) * 0.5
            return CGRect(x: 0, y: topLeftY, width: imageViewSize.width, height: height)
        }
    }
}
extension UIImage
{
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage
    {
        let size = image.size
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        var newSize: CGSize
        if(widthRatio > heightRatio)
        {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
