add_library(3rdparty_protobuf INTERFACE)
if (USE_SYSTEM_PROTOBUF)
	if (USE_LTO)
		# 1. Locate Protobuf (VCPKG compatible)
		find_package(Protobuf REQUIRED)
		
		# 2. Define the pathing variables
		set(NP_PROTO_DIR "${CMAKE_CURRENT_SOURCE_DIR}/rpcs3/Emu/NP/generated")
		set(NP_PROTO_FILE "${NP_PROTO_DIR}/np2_structs.proto")
		set(NP_GEN_DIR "${NP_PROTO_DIR}/generated")
		
		# 3. Create the output directory if it doesn't exist
		file(MAKE_DIRECTORY "${NP_PROTO_DIR}")
		
		# 4. Set the "Base" for imports. 
		# This tells CMake: "Treat the project root as the -I path"
		set_source_files_properties("${NP_PROTO_FILE}" PROPERTIES 
		    PROTOBUF_IMPORT_DIRS "${CMAKE_SOURCE_DIR}"
		)
		
		# 5. Generate the files
		# We use the 'target' version if you have a library, 
		# or the standard version to get the file list.
		protobuf_generate_cpp(NP_PROTO_SRCS NP_PROTO_HDRS "${NP_PROTO_FILE}")
		
		# 6. Crucial: Tell CMake where the headers will end up
		# Because you want them in the 'generated' folder specifically:
		foreach(file ${NP_PROTO_SRCS} ${NP_PROTO_HDRS})
		    set_source_files_properties(${file} PROPERTIES GENERATED TRUE)
		endforeach()
		
		# 7. Add to a target (Example: the NP library)
		add_library(rpcs3_np_proto STATIC ${NP_PROTO_SRCS} ${NP_PROTO_HDRS})
		target_link_libraries(rpcs3_np_proto PRIVATE protobuf::libprotobuf)
		target_include_directories(rpcs3_np_proto PUBLIC "${CMAKE_CURRENT_BINARY_DIR}")
		target_link_libraries(3rdparty_protobuf INTERFACE protobuf::libprotobuf rpcs3_np_proto)
	else()
		pkg_check_modules(PROTOBUF REQUIRED IMPORTED_TARGET protobuf>=33.0.0)
		target_link_libraries(3rdparty_protobuf INTERFACE PkgConfig::PROTOBUF)
	    find_program(PROTOC_EXECUTABLE NAMES protoc REQUIRED)
	    message(STATUS "Using protoc from: ${PROTOC_EXECUTABLE}")
		set(PROTOBUF_DIR_BASE "${CMAKE_SOURCE_DIR}/rpcs3/Emu/NP")
		get_filename_component(PROTOBUF_DIR_BASE "${PROTOBUF_DIR_BASE}" ABSOLUTE)
		set(PROTOBUF_DIR "${PROTOBUF_DIR_BASE}")
		message(STATUS "Normalized Source Dir: ${PROTOBUF_DIR_BASE}")
		file(GLOB FILENAME_LIST "${CMAKE_SOURCE_DIR}/rpcs3/Emu/NP/*.proto")
		message(STATUS "Found proto files: ${FILENAME_LIST}")
		file(MAKE_DIRECTORY "${PROTOBUF_DIR}/generated")
		message(STATUS "Found protobuf directory: ${PROTOBUF_DIR}")
		message(STATUS "Checking if file exists: ${PROTOBUF_DIR}/np2_structs.proto")
		if(EXISTS "${PROTOBUF_DIR}/np2_structs.proto")
		    message(STATUS "File exists!")
		else()
		    message(FATAL_ERROR "File NOT found at that path!")
		endif()
		execute_process(COMMAND "${PROTOC_EXECUTABLE}" --cpp_out="${PROTOBUF_DIR}" --proto_path="${PROTOBUF_DIR}" "${PROTOBUF_DIR}/np2_structs.proto" RESULT_VARIABLE PROTOBUF_CMD_ERROR)
		if(PROTOBUF_CMD_ERROR AND NOT PROTOBUF_CMD_ERROR EQUAL 0)
			message(FATAL_ERROR "protoc failed to regenerate protobuf files.")
		endif()
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
