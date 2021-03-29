import std/[json, os, sets]
import ".."/helpers
import "."/validators

const tags = [
  "paradigm/declarative",
  "paradigm/functional",
  "paradigm/imperative",
  "paradigm/logic",
  "paradigm/object_oriented",
  "paradigm/procedural",
  "typing/static",
  "typing/dynamic",
  "typing/strong",
  "typing/weak",
  "execution_mode/compiled",
  "execution_mode/interpreted",
  "platform/windows",
  "platform/mac",
  "platform/linux",
  "platform/ios",
  "platform/android",
  "platform/web",
  "runtime/standalone_executable",
  "runtime/language_specific",
  "runtime/clr",
  "runtime/jvm",
  "runtime/beam",
  "runtime/wasmtime",
  "used_for/artificial_intelligence",
  "used_for/backends",
  "used_for/cross_platform_development",
  "used_for/embedded_systems",
  "used_for/financial_systems",
  "used_for/frontends",
  "used_for/games",
  "used_for/guis",
  "used_for/mobile",
  "used_for/robotics",
  "used_for/scientific_calculations",
  "used_for/scripts",
  "used_for/web_development",
].toHashSet()

proc isValidTag(data: JsonNode, context: string, path: string): bool =
  result = true

  if data.kind == JString:
    let s = data.getStr()
    if not tags.contains(s):
      result.setFalseAndPrint("Not a valid tag: " & $data, path)
  else:
    result.setFalseAndPrint("Tag is not a string: " & $data, path)

proc hasValidStatus(data: JsonNode, path: string): bool =
  if hasObject(data, "status", path):
    let d = data["status"]
    let checks = [
      hasBoolean(d, "concept_exercises", path),
      hasBoolean(d, "test_runner", path),
      hasBoolean(d, "representer", path),
      hasBoolean(d, "analyzer", path),
    ]
    result = allTrue(checks)

proc hasValidOnlineEditor(data: JsonNode, path: string): bool =
  if hasObject(data, "online_editor", path):
    let d = data["online_editor"]
    const indentStyles = ["space", "tab"].toHashSet()
    let checks = [
      hasString(d, "indent_style", path, allowed = indentStyles),
      hasInteger(d, "indent_size", path, allowed = 0..8),
    ]
    result = allTrue(checks)

proc isValidKeyFeature(data: JsonNode, context: string, path: string): bool =
  if isObject(data, context, path):
    const icons = [
      "todo",
    ].toHashSet()
    # TODO: Enable the `icon` checks when we have a list of valid icons.
    let checks = [
      if false: hasString(data, "icon", path, allowed = icons) else: true,
      hasString(data, "title", path, maxLen = 25),
      hasString(data, "content", path, maxLen = 100),
    ]
    result = allTrue(checks)

proc hasValidKeyFeatures(data: JsonNode, path: string): bool =
  result = hasArrayOf(data, "key_features", path, isValidKeyFeature,
                      isRequired = false, allowedLength = 6..6)

proc isValidTrackConfig(data: JsonNode, path: string): bool =
  if isObject(data, "", path):
    let checks = [
      hasString(data, "language", path),
      hasString(data, "slug", path),
      hasBoolean(data, "active", path),
      hasString(data, "blurb", path, maxLen = 400),
      hasInteger(data, "version", path, allowed = 3..3),
      hasValidStatus(data, path),
      hasValidOnlineEditor(data, path),
      hasValidKeyFeatures(data, path),
      hasArrayOf(data, "tags", path, isValidTag),
    ]
    result = allTrue(checks)

proc isTrackConfigValid*(trackDir: string): bool =
  result = true
  let trackConfigPath = trackDir / "config.json"
  let j = parseJsonFile(trackConfigPath, result)
  if j != nil:
    if not isValidTrackConfig(j, trackConfigPath):
      result = false
