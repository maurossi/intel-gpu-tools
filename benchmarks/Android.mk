LOCAL_PATH := $(call my-dir)

include $(LOCAL_PATH)/Makefile.sources

#================#

define add_benchmark
    include $(CLEAR_VARS)

    LOCAL_SRC_FILES := $1.c

    LOCAL_CFLAGS += -DHAVE_STRUCT_SYSINFO_TOTALRAM
    LOCAL_CFLAGS += -DANDROID -UNDEBUG -include "check-ndebug.h"
    LOCAL_CFLAGS += -std=gnu99
    # FIXME: drop once Bionic correctly annotates "noreturn" on pthread_exit
    LOCAL_CFLAGS += -Wno-error=return-type
    # Excessive complaining for established cases. Rely on the Linux version warnings.
    LOCAL_CFLAGS += -Wno-sign-compare

    LOCAL_MODULE := $1_benchmark
    LOCAL_MODULE_TAGS := optional
    LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR)/intel/validation/core/igt/benchmarks

    LOCAL_STATIC_LIBRARIES := libintel_gpu_tools \
                              libpciaccess

    LOCAL_SHARED_LIBRARIES := libdrm        \
                              libdrm_intel

    include $(BUILD_EXECUTABLE)
endef

#================#

benchmark_list := $(benchmarks_PROGRAMS)

$(foreach item,$(benchmark_list),$(eval $(call add_benchmark,$(item))))
