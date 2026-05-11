load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MQAI",
    module_name = "MQAI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/AccountContext:AccountContext",
        "//submodules/AppBundle:AppBundle",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//Swiftgram/SGSimpleSettings:SGSimpleSettings",
    ],
    visibility = [
        "//visibility:public",
    ],
)
