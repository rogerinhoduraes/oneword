import os
import uuid

def gen_id():
    return uuid.uuid4().hex[:24].upper()

sources_dir = "OneWord/Sources/OneWord"
source_files = []
for root, _, files in os.walk(sources_dir):
    for f in sorted(files):
        if f.endswith(".swift"):
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, "OneWord")
            source_files.append((f, rel_path))

print(f"Found {len(source_files)} Swift source files.")

# Generate deterministic or random IDs
proj_id = gen_id()
main_group_id = gen_id()
sources_group_id = gen_id()
products_group_id = gen_id()
app_target_id = gen_id()
app_product_id = gen_id()
sources_build_phase_id = gen_id()
frameworks_build_phase_id = gen_id()
resources_build_phase_id = gen_id()
config_list_proj_id = gen_id()
config_list_target_id = gen_id()
proj_debug_conf_id = gen_id()
proj_release_conf_id = gen_id()
target_debug_conf_id = gen_id()
target_release_conf_id = gen_id()

source_file_refs = []
source_build_files = []

for fname, rel_path in source_files:
    fref_id = gen_id()
    bfile_id = gen_id()
    source_file_refs.append((fname, rel_path, fref_id))
    source_build_files.append((fname, bfile_id, fref_id))

pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
"""

for fname, bfile_id, fref_id in source_build_files:
    pbx += f"\t\t{bfile_id} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fref_id} /* {fname} */; }};\n"

pbx += f"""/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t{app_product_id} /* OneWord.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = OneWord.app; sourceTree = BUILT_PRODUCTS_DIR; }};
"""

for fname, rel_path, fref_id in source_file_refs:
    pbx += f"\t\t{fref_id} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{rel_path}\"; sourceTree = \"<group>\"; }};\n"

pbx += f"""/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_build_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{sources_group_id} /* OneWord Sources */,
\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_product_id} /* OneWord.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{sources_group_id} /* OneWord Sources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
"""

for fname, _, fref_id in source_file_refs:
    pbx += f"\t\t\t\t{fref_id} /* {fname} */,\n"

pbx += f"""\t\t\t);
\t\t\tname = \"OneWord Sources\";
\t\t\tpath = OneWord;
\t\t\tsourceTree = \"<group>\";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{app_target_id} /* OneWord */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {config_list_target_id} /* Build configuration list for PBXNativeTarget \"OneWord\" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_build_phase_id} /* Sources */,
\t\t\t\t{frameworks_build_phase_id} /* Frameworks */,
\t\t\t\t{resources_build_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = OneWord;
\t\t\tproductName = OneWord;
\t\t\tproductReference = {app_product_id} /* OneWord.app */;
\t\t\tproductType = \"com.apple.product-type.application\";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{proj_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{app_target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {config_list_proj_id} /* Build configuration list for PBXProject \"OneWord\" */;
\t\t\tcompatibilityVersion = \"Xcode 14.0\";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_id};
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = \"\";
\t\t\tprojectRoot = \"\";
\t\t\ttargets = (
\t\t\t\t{app_target_id} /* OneWord */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_build_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_build_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
"""

for fname, bfile_id, _ in source_build_files:
    pbx += f"\t\t\t\t{bfile_id} /* {fname} in Sources */,\n"

pbx += f"""\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{proj_debug_conf_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t\"DEBUG=1\",\n\t\t\t\t\t\"$(inherited)\",
\t\t\t\t);
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = \"DEBUG $(inherited)\";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{proj_release_conf_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = \"wholemodule\";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{target_debug_conf_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = \"OneWord/Sources/OneWord/Resources/Info.plist\";
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = OneWord;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = \"public.app-category.education\";
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t\"$(inherited)\",
\t\t\t\t\t\"@executable_path/Frameworks\",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.oneword.rsvp;
\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{target_release_conf_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = \"OneWord/Sources/OneWord/Resources/Info.plist\";
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = OneWord;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = \"public.app-category.education\";
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t\"$(inherited)\",
\t\t\t\t\t\"@executable_path/Frameworks\",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.oneword.rsvp;
\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{config_list_proj_id} /* Build configuration list for PBXProject \"OneWord\" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{proj_debug_conf_id} /* Debug */,
\t\t\t\t{proj_release_conf_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{config_list_target_id} /* Build configuration list for PBXNativeTarget \"OneWord\" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{target_debug_conf_id} /* Debug */,
\t\t\t\t{target_release_conf_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {proj_id} /* Project object */;
}}
"""

os.makedirs("OneWord.xcodeproj", exist_ok=True)
with open("OneWord.xcodeproj/project.pbxproj", "w") as f:
    f.write(pbx)

print("Generated OneWord.xcodeproj successfully!")
