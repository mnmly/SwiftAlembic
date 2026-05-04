#include "calembic_shared.h"

using namespace Alembic::Abc;

// === Error state ===

namespace {

struct ErrorState {
    CAlembicError code = CAlembicError_OK;
    std::string message;
};

std::mutex g_error_mutex;
ErrorState g_error_state;

} // namespace

void set_error(CAlembicError code, const std::string& msg) {
    std::lock_guard<std::mutex> lock(g_error_mutex);
    g_error_state.code = code;
    g_error_state.message = msg;
}

const char* calembic_last_error() {
    std::lock_guard<std::mutex> lock(g_error_mutex);
    return g_error_state.message.c_str();
}

CAlembicError calembic_last_error_code() {
    std::lock_guard<std::mutex> lock(g_error_mutex);
    return g_error_state.code;
}
