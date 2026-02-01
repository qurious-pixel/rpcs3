add_library(3rdparty_protobuf INTERFACE)

if (USE_SYSTEM_PROTOBUF)
    pkg_check_modules(PROTOBUF REQUIRED IMPORTED_TARGET protobuf>=29.0.0)
    
    find_program(PROTOBUF_PROTOC_EXECUTABLE NAMES protoc REQUIRED)
    message(STATUS "Using protoc from: ${PROTOBUF_PROTOC_EXECUTABLE}")

    # 1. Resolve to a clean absolute path (No trailing slashes)
    get_filename_component(PROTO_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../rpcs3/Emu/NP/generated" ABSOLUTE)
    
    # 2. Ensure directory exists
    file(MAKE_DIRECTORY "${PROTO_DIR}")

    # 3. Define the file (must be an exact child of PROTO_DIR string-wise)
    set(PROTO_INPUT "${PROTO_DIR}/np2_structs.proto")

    if(NOT EXISTS "${PROTO_INPUT}")
        message(FATAL_ERROR "Could not find: ${PROTO_INPUT}")
    endif()

    # 4. Use NATIVE_PATH to handle Windows backslashes correctly for the CLI
    file(TO_NATIVE_PATH "${PROTO_DIR}" PROTO_DIR_NATIVE)
    file(TO_NATIVE_PATH "${PROTO_INPUT}" PROTO_INPUT_NATIVE)

    message(STATUS "Running protoc on: ${PROTO_INPUT_NATIVE}")

    execute_process(
        COMMAND ${PROTOBUF_PROTOC_EXECUTABLE} 
                --cpp_out=. 
                --proto_path=. 
                np2_structs.proto
        WORKING_DIRECTORY "${PROTO_DIR}"
        RESULT_VARIABLE PROTOBUF_CMD_ERROR
        ERROR_VARIABLE PROTOC_STDERR
        OUTPUT_VARIABLE PROTOC_STDOUT
    )

    if(PROTOBUF_CMD_ERROR)
        message(STATUS "Protoc Stderr: ${PROTOC_STDERR}")
        message(FATAL_ERROR "protoc failed to regenerate protobuf files.")
    endif()

    target_link_libraries(3rdparty_protobuf INTERFACE PkgConfig::PROTOBUF)
else()
    option(protobuf_INSTALL "Install protobuf binaries and files" OFF)
    option(protobuf_BUILD_TESTS "Build tests" OFF)
    option(protobuf_BUILD_CONFORMANCE "Build conformance tests" OFF)
    option(protobuf_BUILD_EXAMPLES "Build examples" OFF)
    option(protobuf_BUILD_PROTOBUF_BINARIES "Build protobuf libraries and protoc compiler" ON)
    option(protobuf_BUILD_PROTOC_BINARIES "Build libprotoc and protoc compiler" OFF)
    option(protobuf_BUILD_LIBPROTOC "Build libprotoc" OFF)
    option(protobuf_BUILD_LIBUPB "Build libupb" OFF)
    option(protobuf_ALLOW_CCACHE "Adjust build flags to allow for ccache support." ON)
    option(protobuf_DISABLE_RTTI "Remove runtime type information in the binaries" OFF)
    option(protobuf_FORCE_FETCH_DEPENDENCIES "Force all dependencies to be downloaded from GitHub" OFF)
    option(protobuf_LOCAL_DEPENDENCIES_ONLY "Prevent downloading any dependencies from GitHub" OFF)

    add_subdirectory(protobuf EXCLUDE_FROM_ALL)
    
    target_include_directories(3rdparty_protobuf SYSTEM INTERFACE protobuf/src)
    target_link_libraries(3rdparty_protobuf INTERFACE libprotobuf)
endif()
