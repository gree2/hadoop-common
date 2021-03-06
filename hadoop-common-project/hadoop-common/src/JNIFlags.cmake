#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

cmake_minimum_required(VERSION 2.6 FATAL_ERROR)

find_package(JNI REQUIRED)

# If JVM_ARCH_DATA_MODEL is 32, compile all binaries as 32-bit.
# This variable is set by maven.
if (JVM_ARCH_DATA_MODEL EQUAL 32)
    # Force 32-bit code generation on amd64/x86_64, ppc64, sparc64
    if (CMAKE_COMPILER_IS_GNUCC AND CMAKE_SYSTEM_PROCESSOR MATCHES ".*64")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
        set(CMAKE_LD_FLAGS "${CMAKE_LD_FLAGS} -m32")
    endif ()
    if (CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "amd64")
        set(CMAKE_SYSTEM_PROCESSOR "i686")
    endif ()
endif (JVM_ARCH_DATA_MODEL EQUAL 32)

# Determine float ABI of JVM on ARM Linux
if (CMAKE_SYSTEM_PROCESSOR MATCHES "^arm" AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_program(READELF readelf)
    if (READELF MATCHES "NOTFOUND")
        message(WARNING "readelf not found; JVM float ABI detection disabled")
    else (READELF MATCHES "NOTFOUND")
        execute_process(
            COMMAND ${READELF} -A ${JAVA_JVM_LIBRARY}
            OUTPUT_VARIABLE JVM_ELF_ARCH
            ERROR_QUIET)
        if (NOT JVM_ELF_ARCH MATCHES "Tag_ABI_VFP_args: VFP registers")
            message("Soft-float JVM detected")

            # Test compilation with -mfloat-abi=softfp using an arbitrary libc function
            # (typically fails with "fatal error: bits/predefs.h: No such file or directory"
            # if soft-float dev libraries are not installed)
            include(CMakePushCheckState)
            cmake_push_check_state()
            set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} -mfloat-abi=softfp")
            include(CheckSymbolExists)
            check_symbol_exists(exit stdlib.h SOFTFP_AVAILABLE)
            if (NOT SOFTFP_AVAILABLE)
                message(FATAL_ERROR "Soft-float dev libraries required (e.g. 'apt-get install libc6-dev-armel' on Debian/Ubuntu)")
            endif (NOT SOFTFP_AVAILABLE)
            cmake_pop_check_state()

            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mfloat-abi=softfp")
        endif ()
    endif (READELF MATCHES "NOTFOUND")
endif (CMAKE_SYSTEM_PROCESSOR MATCHES "^arm" AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
