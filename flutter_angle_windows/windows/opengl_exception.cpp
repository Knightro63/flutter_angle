#include "include/headers/opengl_exception.h"

namespace {
    OpenGLException::OpenGLException(char* message, int error){
        this->error = error;
        message = message;
    }
}