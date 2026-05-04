#include "calembic_shared.h"
using namespace Alembic::Abc; using namespace Alembic::AbcGeom;

struct CAlembicOXform { OXform xform; CAlembicOXform(OObject p, const std::string& n) : xform(p, n) {} };
struct CAlembicIXform { IXform xform; CAlembicIXform(IObject o) : xform(o, kWrapExisting) {} };

std::shared_ptr<CAlembicOXform> calembic_create_xform(std::shared_ptr<CAlembicOObject> parent, const std::string& name) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicOXform>(parent->object, name); }
    catch (const std::exception& e) { set_error(CAlembicError_Internal, std::string("create_xform: ") + e.what()); return nullptr; }
}

int calembic_xform_set(const std::shared_ptr<CAlembicOXform>& xform, const CAlembicXformSample& sample) {
    try {
        XformSample s;
        for (auto& op : sample.ops) {
            switch (op.type) {
                case CAlembicXformOp_Translate: s.setTranslation(Imath::V3d(op.values[0], op.values[1], op.values[2])); break;
                case CAlembicXformOp_Rotate: { XformOp r(kRotateOperation, kRotateHint); s.addOp(r, Imath::V3d(op.values[0], op.values[1], op.values[2]), op.values[3]); break; }
                case CAlembicXformOp_Scale: s.setScale(Imath::V3d(op.values[0], op.values[1], op.values[2])); break;
                case CAlembicXformOp_Matrix: s.setMatrix(Imath::M44d(op.values[0],op.values[1],op.values[2],op.values[3],op.values[4],op.values[5],op.values[6],op.values[7],op.values[8],op.values[9],op.values[10],op.values[11],op.values[12],op.values[13],op.values[14],op.values[15])); break;
            }
        }
        s.setInheritsXforms(sample.inherits);
        xform->xform.getSchema().set(s);
        set_error(CAlembicError_OK, ""); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("xform_set: ") + e.what()); return -1; }
}

std::shared_ptr<CAlembicIXform> calembic_object_as_xform(const std::shared_ptr<CAlembicIObject>& obj) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicIXform>(obj->object); }
    catch (const std::exception& e) { set_error(CAlembicError_InvalidSchema, std::string("as_xform: ") + e.what()); return nullptr; }
}

uint32_t calembic_xform_num_samples(const std::shared_ptr<CAlembicIXform>& xform) {
    try { return static_cast<uint32_t>(xform->xform.getSchema().getNumSamples()); } catch (...) { return 0; }
}

int calembic_xform_get(const std::shared_ptr<CAlembicIXform>& xform, uint32_t index, CAlembicXformSample* out) {
    try {
        XformSample sample; xform->xform.getSchema().get(sample, makeSelector(index));
        CAlembicXformSample result; result.inherits = sample.getInheritsXforms();
        size_t numOps = sample.getNumOps();
        for (size_t i = 0; i < numOps; i++) {
            auto& op = sample[i]; CAlembicXformOp cop; auto opType = op.getType(); auto numCh = op.getNumChannels();
            cop.valueCount = static_cast<int>(numCh);
            for (size_t c = 0; c < numCh && c < 16; c++) cop.values[c] = op.getChannelValue(c);
            switch (opType) { case kTranslateOperation: cop.type=CAlembicXformOp_Translate; break; case kRotateOperation: cop.type=CAlembicXformOp_Rotate; break; case kScaleOperation: cop.type=CAlembicXformOp_Scale; break; case kMatrixOperation: cop.type=CAlembicXformOp_Matrix; break; default: continue; }
            result.ops.push_back(cop);
        }
        set_error(CAlembicError_OK, ""); *out = std::move(result); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("xform_get: ") + e.what()); return -1; }
}
