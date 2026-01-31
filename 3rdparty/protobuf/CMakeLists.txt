# --- 3rdparty/protobuf/CMakeLists.txt ---

add_library(3rdparty_protobuf INTERFACE)

if (USE_SYSTEM_PROTOBUF)
    # 1. Locate the system Protobuf package
    pkg_check_modules(PROTOBUF REQUIRED IMPORTED_TARGET protobuf>=29.0.0)
    
    # 2. Find the actual protoc compiler executable
    find_program(PROTOBUF_PROTOC_EXECUTABLE NAMES protoc)
    if(NOT PROTOBUF_PROTOC_EXECUTABLE)
        message(FATAL_ERROR "Found protobuf library, but could not find protoc executable in PATH.")
    endif()

    # 3. Resolve the absolute path to the generated folder to avoid "dumb" prefix errors
    get_filename_component(PROTOBUF_GEN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../rpcs3/Emu/NP/generated/" ABSOLUTE)
    
    # 4. Ensure the output directory exists
    file(MAKE_DIRECTORY "${PROTOBUF_GEN_DIR}")

    # 5. Define the input .proto file path
    set(PROTO_FILE_PATH "${PROTOBUF_GEN_DIR}/np2_structs.proto")

    if(NOT EXISTS "${PROTO_FILE_PATH}")
        message(FATAL_ERROR "Could not find proto file at: ${PROTO_FILE_PATH}")
    endif()

    message(STATUS "Regenerating Protobuf files in: ${PROTOBUF_GEN_DIR}")

    # 6. Execute protoc with absolute paths to satisfy prefix rules
    execute_process(
        COMMAND ${PROTOBUF_PROTOC_EXECUTABLE} 
                --cpp_out="${PROTOBUF_GEN_DIR}" 
                --proto_path="${PROTOBUF_GEN_DIR}" 
                "${PROTO_FILE_PATH}"
        RESULT_VARIABLE PROTOBUF_CMD_ERROR
        ERROR_VARIABLE PROTOC_STDERR
        OUTPUT_VARIABLE PROTOC_STDOUT
    )

    if(PROTOBUF_CMD_ERROR AND NOT PROTOBUF_CMD_ERROR EQUAL 0)
        message(STATUS "Protoc Stdout: ${PROTOC_STDOUT}")
        message(STATUS "Protoc Stderr: ${PROTOC_STDERR}")
        message(FATAL_ERROR "protoc failed to regenerate protobuf files. Exit code: ${PROTOBUF_CMD_ERROR}")
    endif()

    target_link_libraries(3rdparty_protobuf INTERFACE PkgConfig::PROTOBUF)

else()
    # Built-in fallback logic
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
