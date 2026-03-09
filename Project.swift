import ProjectDescription

let project = Project(
    name: "GitHubSearch",
    organizationName: "com.githubsearch",
    settings: .settings(
        base: ["SWIFT_VERSION": "5.9"]
    ),
    targets: [
        .target(
            name: "GitHubSearch",
            destinations: .iOS,
            product: .app,
            bundleId: "com.githubsearch.GitHubSearch",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "UIApplicationSceneManifest": [
                        "UIApplicationSupportsMultipleScenes": false,
                        "UISceneConfigurations": [
                            "UIWindowSceneSessionRoleApplication": [
                                [
                                    "UISceneConfigurationName": "Default Configuration",
                                    "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                                ]
                            ]
                        ]
                    ]
                ]
            ),
            sources: ["Sources/**"],
            resources: [],
            dependencies: []
        ),
        .target(
            name: "GitHubSearchTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.githubsearch.GitHubSearchTests",
            deploymentTargets: .iOS("17.0"),
            sources: [
                "Tests/DomainTests/**",
                "Tests/DataTests/**",
                "Tests/PresentationTests/**"
            ],
            dependencies: [
                .target(name: "GitHubSearch")
            ]
        ),
        .target(
            name: "GitHubSearchUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.githubsearch.GitHubSearchUITests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/UITests/**"],
            dependencies: [
                .target(name: "GitHubSearch")
            ]
        )
    ]
)
