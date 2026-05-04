#include "calembic_shared.h"
using namespace Alembic::Abc; using namespace Alembic::AbcGeom;

struct CAlembicOFaceSet { OFaceSet faceset; CAlembicOFaceSet(OObject p, const std::string& n) : faceset(p, n) {} };
struct CAlembicIFaceSet { IFaceSet faceset; CAlembicIFaceSet(IObject o) : faceset(o, kWrapExisting) {} };

std::shared_ptr<CAlembicOFaceSet> calembic_create_faceset(std::shared_ptr<CAlembicOObject> parent, const std::string& name) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicOFaceSet>(parent->object, name); }
    catch (const std::exception& e) { set_error(CAlembicError_Internal, std::string("create_faceset: ") + e.what()); return nullptr; }
}

int calembic_faceset_set(const std::shared_ptr<CAlembicOFaceSet>& faceset, const CAlembicFaceSetSample& sample) {
    try {
        OFaceSetSchema::Sample s; s.setFaces(Int32ArraySample(sample.faceIndices.data(), sample.faceIndices.size()));
        if (sample.selfBoundsSet) s.setSelfBounds(toBox3d(sample.selfBounds));
        faceset->faceset.getSchema().set(s);
        set_error(CAlembicError_OK, ""); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("faceset_set: ") + e.what()); return -1; }
}

std::shared_ptr<CAlembicIFaceSet> calembic_object_as_faceset(const std::shared_ptr<CAlembicIObject>& obj) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicIFaceSet>(obj->object); }
    catch (const std::exception& e) { set_error(CAlembicError_InvalidSchema, std::string("as_faceset: ") + e.what()); return nullptr; }
}

uint32_t calembic_faceset_num_samples(const std::shared_ptr<CAlembicIFaceSet>& faceset) {
    try { return static_cast<uint32_t>(faceset->faceset.getSchema().getNumSamples()); } catch (...) { return 0; }
}

int calembic_faceset_get(const std::shared_ptr<CAlembicIFaceSet>& faceset, uint32_t index, CAlembicFaceSetSample* out) {
    try {
        IFaceSetSchema::Sample sample; faceset->faceset.getSchema().get(sample, makeSelector(index));
        CAlembicFaceSetSample result; result.selfBoundsSet = false;
        auto fPtr = sample.getFaces(); if (fPtr && fPtr->size() > 0) result.faceIndices.assign(fPtr->get(), fPtr->get() + fPtr->size());
        if (sample.getSelfBounds().hasVolume()) { result.selfBounds = fromBox3d(sample.getSelfBounds()); result.selfBoundsSet = true; }
        set_error(CAlembicError_OK, ""); *out = std::move(result); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("faceset_get: ") + e.what()); return -1; }
}
