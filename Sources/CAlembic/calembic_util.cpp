#include "calembic_shared.h"

using namespace Alembic::Abc;

// Per-thread error state — eliminates the global mutex and the race window
// between a C++ wrapper setting the error and the Swift caller reading it.

namespace {

struct ErrorState {
    CAlembicError code = CAlembicError_OK;
    std::string message;
};

thread_local ErrorState tl_error;

} // namespace

void set_error(CAlembicError code, const std::string& msg) {
    tl_error.code = code;
    tl_error.message = msg;
}

const char* calembic_last_error() {
    return tl_error.message.c_str();
}

CAlembicError calembic_last_error_code() {
    return tl_error.code;
}
