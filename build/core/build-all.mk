# Copyright (C) 2009-2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This script is used to build all wanted NDK binaries. It is included
# by several scripts.
#

# ensure that the following variables are properly defined
$(call assert-defined,NDK_APPS NDK_APP_OUT)

# ====================================================================
#
# Prepare the build for parsing Android.mk files
#
# ====================================================================

# These phony targets are used to control various stages of the build
.PHONY: all \
	copy-llvm-toolchains \
        host_libraries host_executables \
        installed_modules \
        executables libraries static_libraries shared_libraries \
        clean clean-objs-dir \
        clean-executables clean-libraries \
        clean-installed-modules \
        clean-installed-binaries

# These macros are used in Android.mk to include the corresponding
# build script that will parse the LOCAL_XXX variable definitions.
#
CLEAR_VARS                := $(BUILD_SYSTEM)/clear-vars.mk
BUILD_HOST_EXECUTABLE     := $(BUILD_SYSTEM)/build-host-executable.mk
BUILD_HOST_STATIC_LIBRARY := $(BUILD_SYSTEM)/build-host-static-library.mk
BUILD_STATIC_LIBRARY      := $(BUILD_SYSTEM)/build-static-library.mk
BUILD_SHARED_LIBRARY      := $(BUILD_SYSTEM)/build-shared-library.mk
BUILD_EXECUTABLE          := $(BUILD_SYSTEM)/build-executable.mk
BUILD_BITCODE		  := $(BUILD_SYSTEM)/build-bitcode.mk
PREBUILT_SHARED_LIBRARY   := $(BUILD_SYSTEM)/prebuilt-shared-library.mk
PREBUILT_STATIC_LIBRARY   := $(BUILD_SYSTEM)/prebuilt-static-library.mk

ANDROID_MK_INCLUDED := \
  $(CLEAR_VARS) \
  $(BUILD_HOST_EXECUTABLE) \
  $(BUILD_HOST_STATIC_LIBRARY) \
  $(BUILD_STATIC_LIBRARY) \
  $(BUILD_SHARED_LIBRARY) \
  $(BUILD_EXECUTABLE) \
  $(BUILD_BITCODE) \
  $(PREBUILT_SHARED_LIBRARY) \


# this is the list of directories containing dependency information
# generated during the build. It will be updated by build scripts
# when module definitions are parsed.
#
ALL_DEPENDENCY_DIRS :=

# this is the list of all generated files that we would need to clean
ALL_HOST_EXECUTABLES      :=
ALL_HOST_STATIC_LIBRARIES :=
ALL_STATIC_LIBRARIES      :=
ALL_SHARED_LIBRARIES      :=
ALL_EXECUTABLES           :=
ALL_BITCODE		  :=

WANTED_INSTALLED_MODULES  :=

# the first rule
all: copy-llvm-toolchains installed_modules host_libraries host_executables


ANDROID_SOURCE_ROOT := $(NDK_ROOT)/../
copy-llvm-toolchains:
	$(info **********************************************************************)
	$(info Copy llvm toolchains from Android source tree...)
	$(info If copy failed, please go to $(NDK_ROOT)/sources/llvm-ndk-cc/ and build them at first.)
	$(info **********************************************************************)
	@mkdir -p $(NDK_ROOT)/toolchains/llvm/prebuilt/linux-x86/bin/
	@cp -p $(ANDROID_SOURCE_ROOT)/out/host/linux-x86/bin/llvm-ndk-cc \
	    $(NDK_ROOT)/toolchains/llvm/prebuilt/linux-x86/bin/
	@cp -p $(ANDROID_SOURCE_ROOT)/out/host/linux-x86/bin/llvm-ndk-link \
	    $(NDK_ROOT)/toolchains/llvm/prebuilt/linux-x86/bin/

	$(info Copy NDK toolchains to toolchains/arm-linux-androideabi-4.4.3/prebuilt)
	$(info **********************************************************************)
	@mkdir -p $(NDK_ROOT)/toolchains/arm-linux-androideabi-4.4.3/
	@cp -r $(NDK_ROOT)/../ndk/toolchains/arm-linux-androideabi-4.4.3/prebuilt $(NDK_ROOT)/toolchains/arm-linux-androideabi-4.4.3/prebuilt

	$(info Copy clang from Android source tree...)
	$(info If copy failed, please go to $(ANDROID_SOURCE_ROOT)/external/llvm and build them at first.)
	$(info **********************************************************************)
	@cp -p $(ANDROID_SOURCE_ROOT)/out/host/linux-x86/bin/clang \
	    $(NDK_ROOT)/toolchains/llvm/prebuilt/linux-x86/bin/llvm-ndk-cc



$(foreach _app,$(NDK_APPS),\
  $(eval include $(BUILD_SYSTEM)/setup-app.mk)\
)

# ====================================================================
#
# Now finish the build preparation with a few rules that depend on
# what has been effectively parsed and recorded previously
#
# ====================================================================

clean: clean-intermediates clean-installed-binaries

distclean: clean

installed_modules: clean-installed-binaries libraries $(WANTED_INSTALLED_MODULES)
host_libraries: $(HOST_STATIC_LIBRARIES)
host_executables: $(HOST_EXECUTABLES)

static_libraries: $(STATIC_LIBRARIES)
shared_libraries: $(SHARED_LIBRARIES)
executables: $(EXECUTABLES)

libraries: static_libraries shared_libraries

clean-host-intermediates:
	$(hide) rm -rf $(HOST_EXECUTABLES) $(HOST_STATIC_LIBRARIES)

clean-intermediates: clean-host-intermediates
	$(hide) rm -rf $(EXECUTABLES) $(STATIC_LIBRARIES) $(SHARED_LIBRARIES)

# include dependency information
ALL_DEPENDENCY_DIRS := $(sort $(ALL_DEPENDENCY_DIRS))
-include $(wildcard $(ALL_DEPENDENCY_DIRS:%=%/*.d))