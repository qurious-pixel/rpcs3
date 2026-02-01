# --- 3rdparty/protobuf/CMakeLists.txt ---

add_library(3rdparty_protobuf INTERFACE)

if (USE_SYSTEM_PROTOBUF)
    pkg_check_modules(PROTOBUF REQUIRED IMPORTED_TARGET protobuf>=29.0.0)
    
    # Locate the compiler and log it for GitHub Actions visibility
    find_program(PROTOBUF_PROTOC_EXECUTABLE NAMES protoc REQUIRED)
    message(STATUS "Using protoc from: ${PROTOBUF_PROTOC_EXECUTABLE}")

    # Normalize the path to avoid "protoc is too dumb" errors
    get_filename_component(PROTOBUF_GEN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../rpcs3/Emu/NP/generated" ABSOLUTE)
    file(MAKE_DIRECTORY "${PROTOBUF_GEN_DIR}")

    execute_process(
        COMMAND ${PROTOBUF_PROTOC_EXECUTABLE} 
                --cpp_out="${PROTOBUF_GEN_DIR}" 
                --proto_path="${PROTOBUF_GEN_DIR}" 
                "${PROTOBUF_GEN_DIR}/np2_structs.proto"
        RESULT_VARIABLE PROTOBUF_CMD_ERROR
        ERROR_VARIABLE PROTOC_STDERR
    )

    if(PROTOBUF_CMD_ERROR)
        message(FATAL_ERROR "Protoc failed with error: ${PROTOC_STDERR}")
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
