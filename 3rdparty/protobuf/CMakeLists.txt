add_library(3rdparty_protobuf INTERFACE)
if (USE_SYSTEM_PROTOBUF)
	pkg_check_modules(PROTOBUF REQUIRED IMPORTED_TARGET protobuf>=29.0.0)
	target_link_libraries(3rdparty_protobuf INTERFACE PkgConfig::PROTOBUF)
	set(PROTOBUF_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../rpcs3/Emu/NP/generated/")
	execute_process(
	    COMMAND protoc --cpp_out="${PROTOBUF_DIR}" --proto_path="${PROTOBUF_DIR}" np2_structs.proto 
	    OUTPUT_VARIABLE PROTOC_OUT 
	    ERROR_VARIABLE PROTOC_ERR
	    RESULT_VARIABLE PROTOBUF_CMD_ERROR
	)
	if(PROTOBUF_CMD_ERROR)
	    message(STATUS "Protoc Output: ${PROTOC_OUT}")
	    message(STATUS "Protoc Error: ${PROTOC_ERR}")
	    message(FATAL_ERROR "protoc failed...")
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
	target_include_directories(3rdparty_protobuf SYSTEM INTERFACE protobuf/src)
	target_link_libraries(3rdparty_protobuf INTERFACE libprotobuf)
endif()
