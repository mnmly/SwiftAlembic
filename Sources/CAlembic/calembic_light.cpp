#include "calembic_shared.h"
using namespace Alembic::Abc; using namespace Alembic::AbcGeom;

struct CAlembicOLight { OLight light; CAlembicOLight(OObject p, const std::string& n) : light(p, n) {} };
struct CAlembicILight { ILight light; CAlembicILight(IObject o) : light(o, kWrapExisting) {} };

std::shared_ptr<CAlembicOLight> calembic_create_light(std::shared_ptr<CAlembicOObject> parent, const std::string& name) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicOLight>(parent->object, name); }
    catch (const std::exception& e) { set_error(CAlembicError_Internal, std::string("create_light: ") + e.what()); return nullptr; }
}

int calembic_light_set(const std::shared_ptr<CAlembicOLight>& light, const CAlembicLightSample&) {
    try {
        CameraSample s;
        light->light.getSchema().setCameraSample(s);
        set_error(CAlembicError_OK, ""); return 0;
    }
    catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("light_set: ") + e.what()); return -1; }
}

std::shared_ptr<CAlembicILight> calembic_object_as_light(const std::shared_ptr<CAlembicIObject>& obj) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicILight>(obj->object); }
    catch (const std::exception& e) { set_error(CAlembicError_InvalidSchema, std::string("as_light: ") + e.what()); return nullptr; }
}

uint32_t calembic_light_num_samples(const std::shared_ptr<CAlembicILight>& light) {
    try { return static_cast<uint32_t>(light->light.getSchema().getNumSamples()); } catch (...) { return 0; }
}

int calembic_light_get(const std::shared_ptr<CAlembicILight>& light, uint32_t index, CAlembicLightSample* out) {
    try { CAlembicLightSample result; result.selfBoundsSet = false; set_error(CAlembicError_OK, ""); *out = std::move(result); return 0; }
    catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("light_get: ") + e.what()); return -1; }
}
