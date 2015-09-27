LOCAL_PATH := $(call my-dir)

include $(LOCAL_PATH)/Makefile.sources

#================#
# each igt test is a separate executable. define a function to build one of these tests
define add_test
    include $(CLEAR_VARS)

    # specific to this test
    LOCAL_SRC_FILES := $1.c
    LOCAL_MODULE := $1

    # common to all tests
    LOCAL_CFLAGS += ${IGT_LOCAL_CFLAGS}
    LOCAL_C_INCLUDES = ${IGT_LOCAL_C_INCLUDES}
    LOCAL_STATIC_LIBRARIES := ${IGT_LOCAL_STATIC_LIBRARIES}
    LOCAL_SHARED_LIBRARIES := ${IGT_LOCAL_SHARED_LIBRARIES}

    LOCAL_MODULE_TAGS := optional
    # ask linker to define a specific symbol; we use this to identify IGT tests
    LOCAL_LDFLAGS := -Wl,--defsym=$2=0
    LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR)/intel/validation/core/igt

    include $(BUILD_EXECUTABLE)
endef


# some tests still do not build under android
skip_tests_list :=
skip_tests_list += testdisplay        # needs glib.h
skip_tests_list += pm_rpm

# set local compilation flags for IGT tests
IGT_LOCAL_CFLAGS += -DHAVE_STRUCT_SYSINFO_TOTALRAM -DANDROID -UNDEBUG
IGT_LOCAL_CFLAGS += -include "check-ndebug.h" -std=gnu99
# FIXME: drop once Bionic correctly annotates "noreturn" on pthread_exit
IGT_LOCAL_CFLAGS += -Wno-error=return-type
# Excessive complaining for established cases. Rely on the Linux version warnings.
IGT_LOCAL_CFLAGS += -Wno-sign-compare

# set local includes
IGT_LOCAL_C_INCLUDES = $(LOCAL_PATH)/../lib
IGT_LOCAL_C_INCLUDES += ${ANDROID_BUILD_TOP}/external/drm/include/drm

# set local libraries
IGT_LOCAL_STATIC_LIBRARIES := libintel_gpu_tools libpciaccess
IGT_LOCAL_SHARED_LIBRARIES := libdrm libdrm_intel

# handle cairo requirements if it is enabled
ifeq ("${ANDROID_HAS_CAIRO}", "1")
    IGT_LOCAL_C_INCLUDES += ${ANDROID_BUILD_TOP}/external/cairo-1.12.16/src
    IGT_LOCAL_SHARED_LIBRARIES += libcairo
    IGT_LOCAL_CFLAGS += -DANDROID_HAS_CAIRO=1
else
# the following tests depend on cairo, so skip them
    skip_tests_list += \
    gem_render_copy \
    pm_lpsp

# All kms tests depend on cairo
    tmp_list := $(foreach test_name, $(TESTS_progs),\
        $(if $(findstring kms_,$(test_name)),$(test_name)))
    skip_tests_list += $(tmp_list)

    tmp_list := $(foreach test_name, $(TESTS_progs_M),\
        $(if $(findstring kms_,$(test_name)),$(test_name)))
    skip_tests_list += $(tmp_list)

    IGT_LOCAL_CFLAGS += -DANDROID_HAS_CAIRO=0
endif

# create two test lists, one for simple single tests, one for tests that have subtests
tests_list   := $(filter-out $(skip_tests_list),$(TESTS_progs) $(HANG) $(TESTS_testsuite))
tests_list_M := $(filter-out $(skip_tests_list),$(TESTS_progs_M))

$(foreach item,$(tests_list),$(eval $(call add_test,$(item),"IGT_SINGLE_TEST")))
$(foreach item,$(tests_list_M),$(eval $(call add_test,$(item),"IGT_MULTI_TEST")))

