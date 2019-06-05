//
// LiveView.swift
//
// Copyright (c) 2019 Puzyrev Pavel
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Photos
import PhotosUI

open class LiveView: UIView, LiveViewInterface {

    // MARK: - Public Types

    public typealias Completion = ((Error?) -> Void)

    public enum Status {
        case waitingForResource
        case preparingToShow
        case showingResource
    }

    public struct Settings {
        let duration: TimeInterval
        let blurStyle: UIBlurEffect.Style?
        static let `default` = Settings(duration: 0.25, blurStyle: .dark)
    }

    // MARK: - Public Properties

    open var status: LiveView.Status = .waitingForResource
    open var settings: Settings = .default

    // MARK: - Private Properties

    private let imageView     = UIImageView()
    private let livePhotoView = PHLivePhotoView()
    private let blurView      = UIVisualEffectView()

    private lazy var liveResource = {
        return LiveResource()
    }()

    // MARK: - Overrides

    open override var contentMode: ContentMode {
        didSet { subviews.forEach({ $0.contentMode = contentMode }) }
    }

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - Public Methods

    open func show(placeholderImage imageResource: ImageConvertible, animated: Bool, completionHandler: Completion? = nil) {
        do {
            let image = try imageResource.asImage()

            update(image: image, livePhoto: nil, enableBlur: true, animated: animated, completion: {
                self.status = .waitingForResource
                completionHandler?(nil)
            })
        } catch { completionHandler?(error) }
    }

    open func show(image imageResource: ImageConvertible, animated: Bool, completionHandler: Completion? = nil) {
        do {
            let image = try imageResource.asImage()

            update(image: image, livePhoto: nil, enableBlur: false, animated: animated, completion: {
                self.status = .showingResource
                completionHandler?(nil)
            })

        } catch { completionHandler?(error) }
    }

    open func show(imageResource: PathConvertible, movieResource: PathConvertible, animated: Bool, completionHandler: Completion? = nil) {
        let previousStatus = status
        status = .preparingToShow

        liveResource.requestWith(imageResource: imageResource, movieResource: movieResource, size: frame.size) { livePhoto, error in
            if let error = error {
                self.status = previousStatus
                completionHandler?(error)
            } else {
                self.status = .showingResource
                self.update(image: nil, livePhoto: livePhoto, enableBlur: false, animated: animated, completion: {
                    completionHandler?(nil)
                })
            }
        }
    }

    open func saveToLibrary(completionHandler: LiveView.Completion?) {
        guard status == .showingResource else {
            completionHandler?(LKError.nothingToSave)
            return
        }

        if let _ = livePhotoView.livePhoto {
            liveResource.save(completionHandler: completionHandler)
        } else if let image = imageView.image {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { _, error in
                completionHandler?(error)
            })
        } else {
            completionHandler?(LKError.nothingToSave)
        }
    }

    // MARK: - Private Methods

    private func setup() {
        addSubviews([imageView, livePhotoView, blurView])
        pinViews([imageView, livePhotoView, blurView])

        imageView.backgroundColor = .clear
        livePhotoView.backgroundColor = .clear
        blurView.effect = UIBlurEffect(style: .regular)
        blurView.backgroundColor = .clear
    }

}

// MARK: – Transitions

extension LiveView {
    private func update(image: UIImage?,
                        livePhoto: PHLivePhoto?,
                        enableBlur: Bool,
                        animated: Bool,
                        completion: @escaping (() -> Void)) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        setImage(image, animated: animated)
        setLivePhoto(livePhoto, animated: animated)
        setBlurEnabled(enableBlur, animated: animated)
        CATransaction.commit()
    }

    private func setImage(_ image: UIImage?, animated: Bool) {
        let closure = { self.imageView.image = image}
        UIView.transition(with: imageView, duration: settings.duration, animated: animated, closure: closure)
    }

    private func setLivePhoto(_ livePhoto: PHLivePhoto?, animated: Bool) {
        let closure = { self.livePhotoView.livePhoto = livePhoto }
        UIView.transition(with: livePhotoView, duration: settings.duration, animated: animated, closure: closure)
    }

    private func setBlurEnabled(_ isBlurEnabled: Bool, animated: Bool) {
        let effect: UIBlurEffect? = {
            if let blurStyle = settings.blurStyle, isBlurEnabled {
                return UIBlurEffect(style: blurStyle)
            } else {
                return nil
            }
        }()

        let closure = { self.blurView.effect = effect }
        blurView.isHidden = false
        UIView.transition(with: blurView, duration: settings.duration, animated: animated, closure: closure) {
            self.blurView.isHidden = !isBlurEnabled
        }
    }
}


// MARK: - Helpers

fileprivate extension UIView {
    static func transition(with view: UIView, duration: TimeInterval, animated: Bool, closure: @escaping (() -> Void), completion: (() -> Void)? = nil) {
        if animated {
            UIView.transition(with: view,
                    duration: duration,
                    options: .transitionCrossDissolve,
                    animations: closure,
                    completion: { _ in completion?() })
        } else {  closure() }
    }

    func pinViews(_ views: [UIView]) {
        views.forEach({ view in
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                leftAnchor.constraint(equalTo: view.leftAnchor),
                rightAnchor.constraint(equalTo: view.rightAnchor),
                topAnchor.constraint(equalTo: view.topAnchor),
                bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        })
    }
    func addSubviews(_ subviews: [UIView]) {
        subviews.forEach({ addSubview($0) })
    }
}
