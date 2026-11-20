find_package(Qt6 REQUIRED COMPONENTS QuickTest)

qt_add_executable(TaidaEnvControlTests
    main.cpp
    ../Core/TaidaEnvControlProxy.h
    ../Core/TaidaEnvControlProxy.cpp
)
target_link_libraries(TaidaEnvControlTests PRIVATE Qt6::QuickTest Qt6::Qml Qt6::Quick)
target_compile_definitions(TaidaEnvControlTests PRIVATE
    QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
)
add_test(NAME TaidaEnvControlInteractions COMMAND TaidaEnvControlTests -platform offscreen)

# 使用目前建置版本的 Qt，避免載入舊部署目錄的測試平台元件。
get_target_property(test_qmake Qt6::qmake IMPORTED_LOCATION)
execute_process(COMMAND "${test_qmake}" -query QT_INSTALL_PREFIX
    OUTPUT_VARIABLE test_qt_prefix OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)
set_tests_properties(TaidaEnvControlInteractions PROPERTIES ENVIRONMENT
    "QT_PLUGIN_PATH=${test_qt_prefix}/plugins;QML_IMPORT_PATH=${test_qt_prefix}/qml;QT_QUICK_CONTROLS_STYLE=Basic")
if (WIN32)
    set(test_path "${test_qt_prefix}/bin;$ENV{PATH}")
    string(REPLACE ";" "\\;" test_path "${test_path}")
    set_property(TEST TaidaEnvControlInteractions APPEND PROPERTY ENVIRONMENT "PATH=${test_path}")
endif()
