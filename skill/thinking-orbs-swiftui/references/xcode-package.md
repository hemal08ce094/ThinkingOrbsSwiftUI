# Wiring the ThinkingOrbs package

Package URL: `https://github.com/hemal08ce094/ThinkingOrbsSwiftUI`, product `ThinkingOrbs`, versions from `0.1.0`.

## Swift package manifest

```swift
dependencies: [
    .package(url: "https://github.com/hemal08ce094/ThinkingOrbsSwiftUI", from: "0.1.0"),
],
targets: [
    .target(name: "App", dependencies: [.product(name: "ThinkingOrbs", package: "ThinkingOrbsSwiftUI")]),
]
```

## Xcode project (edit project.pbxproj directly)

Pick four unused 24-hex-digit object IDs: REF, DEP, BUILD, plus the target's existing Frameworks phase ID. Then add:

```
/* Begin PBXBuildFile section */
		BUILD /* ThinkingOrbs in Frameworks */ = {isa = PBXBuildFile; productRef = DEP /* ThinkingOrbs */; };
/* End PBXBuildFile section */
```
(If the section already exists, add just the line.)

In the app target's `PBXFrameworksBuildPhase` `files = ( … )`, add `BUILD /* ThinkingOrbs in Frameworks */,`

In the app's `PBXNativeTarget`, add (or extend):
```
			packageProductDependencies = (
				DEP /* ThinkingOrbs */,
			);
```

In `PBXProject`, add (or extend):
```
			packageReferences = (
				REF /* XCRemoteSwiftPackageReference "ThinkingOrbsSwiftUI" */,
			);
```

At the end of `objects`:
```
/* Begin XCRemoteSwiftPackageReference section */
		REF /* XCRemoteSwiftPackageReference "ThinkingOrbsSwiftUI" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/hemal08ce094/ThinkingOrbsSwiftUI";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = 0.1.0;
			};
		};
/* End XCRemoteSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		DEP /* ThinkingOrbs */ = {
			isa = XCSwiftPackageProductDependency;
			package = REF /* XCRemoteSwiftPackageReference "ThinkingOrbsSwiftUI" */;
			productName = ThinkingOrbs;
		};
/* End XCSwiftPackageProductDependency section */
```

Then run `xcodebuild -resolvePackageDependencies` and build. Xcode may reorder sections on its next save; that's fine.

If Xcode is `/Library/Developer/CommandLineTools`, prefix the commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

## Local development instead

To edit the library alongside an app, use `XCLocalSwiftPackageReference` with `relativePath = "path/to/ThinkingOrbsSwiftUI";` in place of the remote reference, and drop `package =` from the product dependency. The repo's own `Demo/ThinkingOrbsDemo.xcodeproj` is set up this way.
