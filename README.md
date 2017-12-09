# MMDSceneKit
SceneKit expansion for MikuMikuDance

![ScreenShot](https://github.com/magicien/MMDSceneKit/blob/master/screenshot.png)

## Install

Download **MMDSceneKit_vX.X.X.zip** from [Releases](https://github.com/magicien/MMDSceneKit/releases/latest).

## Usage

### Swift
```
import MMDSceneKit_macOS

guard let sceneSource = MMDSceneSource(named: "art.scnassets/projectFile.pmm") else { return }
var scene = sceneSource.getScene()
```

### Objective-C
```
@import MMDSceneKit_macOS;

MMDSceneSource *source = [[MMDSceneSource alloc] initWithNamed:@"art.scnassets/projectFile.pmm" options:nil models:nil];
SCNScene *scene = [source getScene];
```

### See Also

[MikuMikuDanceQuickLook](https://github.com/magicien/MikuMikuDanceQuickLook) - macOS QuickLook plugin for MikuMikuDance files
