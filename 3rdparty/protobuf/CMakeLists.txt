add_library(3rdparty_protobuf INTERFACE)
#if(VCPKG_TOOLCHAIN_FILE)
	#message(STATUS "VCPKG_ROOT: ${VCPKG_ROOT}")
    #message(STATUS "Vcpkg installed path: D:/a/rpcs3/rpcs3/build/vcpkg_installed/x64-windows/include/google/protobuf")
    #set(CMAKE_IGNORE_PATH "D:/a/rpcs3/rpcs3/build/vcpkg_installed/x64-windows/include/google/protobuf")
#endif()
if (USE_SYSTEM_PROTOBUF)
	pkg_check_modules(PROTOBUF REQUIRED IMPORTED_TARGET protobuf>=33.0.0)
	target_link_libraries(3rdparty_protobuf INTERFACE PkgConfig::PROTOBUF)
	set(PROTOBUF_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../rpcs3/Emu/NP/generated/")
	execute_process(COMMAND protoc --cpp_out="${PROTOBUF_DIR}" --proto_path="${PROTOBUF_DIR}" np2_structs.proto RESULT_VARIABLE PROTOBUF_CMD_ERROR)
	if(PROTOBUF_CMD_ERROR AND NOT PROTOBUF_CMD_ERROR EQUAL 0)
		message(FATAL_ERROR "protoc failed to regenerate protobuf files.")
	endif()
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
	option(protobuf_FORCE_FETCH_DEPENDENCIES "Force all dependencies to be downloaded from GitHub.  Local installations will be ignored." OFF)
	option(protobuf_LOCAL_DEPENDENCIES_ONLY "Prevent downloading any dependencies from GitHub. If this option is set, the dependency must be available locally as an installed package." OFF)

	add_subdirectory(protobuf EXCLUDE_FROM_ALL)
	#target_include_directories(3rdparty_protobuf SYSTEM INTERFACE protobuf/src)
	target_include_directories(3rdparty_protobuf BEFORE INTERFACE 
        "${CMAKE_CURRENT_SOURCE_DIR}/protobuf/src"
    )
	target_link_libraries(3rdparty_protobuf INTERFACE libprotobuf)
	set(PROTOC_EXECUTABLE $<TARGET_FILE:protoc>)
    set(PROTOBUF_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../rpcs3/Emu/NP/generated/")
    # 1. Define where the generated files will go
    set(PROTO_SRC "${PROTOBUF_DIR}/np2_structs.pb.cc")
    set(PROTO_HDR "${PROTOBUF_DIR}/np2_structs.pb.h")

    # 2. Tell CMake how to generate these files
    add_custom_command(
        OUTPUT "${PROTO_SRC}" "${PROTO_HDR}"
    COMMAND protoc --cpp_out="${PROTOBUF_DIR}" --proto_path="${PROTOBUF_DIR}" np2_structs.proto
    DEPENDS protoc "${PROTOBUF_DIR}/np2_structs.proto"
    WORKING_DIRECTORY "${PROTOBUF_DIR}"
    COMMENT "Running C++ protocol buffer compiler on np2_structs.proto"
    VERBATIM
    )

# 3. Add the generated files to your library/executable
# This triggers the custom command above when you build this target
target_sources(3rdparty_protobuf INTERFACE "${PROTO_SRC}" "${PROTO_HDR}")
endif()
