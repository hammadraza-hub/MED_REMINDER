import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  // M21 step 4: the app switcher takes a snapshot of the window when the app
  // stops being active. Cover the window first so health data is not in it.
  private var privacyCover: UIView?

  override func sceneWillResignActive(_ scene: UIScene) {
    if let windowScene = scene as? UIWindowScene,
      let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
    {
      let cover = UIView(frame: window.bounds)
      cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      cover.backgroundColor = UIColor(red: 0.0, green: 0.35, blue: 0.43, alpha: 1.0)
      window.addSubview(cover)
      privacyCover = cover
    }
    super.sceneWillResignActive(scene)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    privacyCover?.removeFromSuperview()
    privacyCover = nil
    super.sceneDidBecomeActive(scene)
  }
}
